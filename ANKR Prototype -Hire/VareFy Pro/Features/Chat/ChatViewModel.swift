import Foundation
import Observation
import StreamChat
import Supabase

@Observable
class ChatViewModel {

    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private var channelController: ChatChannelController?
    private let delegateProxy = DelegateProxy()

    static let apiKey = "ceexz838897y"
    static private(set) var client: ChatClient?

    init() {
        delegateProxy.owner = self
    }

    // MARK: - Static connect / disconnect (called by AuthManager)

    static func connect(userId: String, displayName: String? = nil) async {
        guard client == nil else { return }

        var config = ChatClientConfig(apiKeyString: apiKey)
        config.isLocalStorageEnabled = false
        let newClient = ChatClient(config: config)

        do {
            struct TokenResponse: Decodable {
                let token: String
            }
            let resp: TokenResponse = try await supabase.functions
                .invoke("generate-stream-token")
            let token = try Token(rawValue: resp.token)
            try await newClient.connectUser(
                userInfo: UserInfo(id: userId, name: displayName),
                token: token
            )
            client = newClient
            print("ChatViewModel: connected as \(userId)")
        } catch {
            print("ChatViewModel: Stream connect failed — \(error)")
        }
    }

    static func disconnect() async {
        await client?.disconnect()
        client = nil
    }

    // Returns true if the currently connected user has sent at least one message
    // in the work order channel. Returns false if the channel doesn't exist yet.
    static func currentUserHasSentMessage(inChannelFor workOrderId: UUID) async -> Bool {
        guard let client else { return false }
        guard let currentUserId = client.currentUserId else { return false }
        let channelId = ChannelId(
            type: .messaging,
            id: "work_order_\(workOrderId.uuidString.lowercased())"
        )
        do {
            let controller = try client.channelController(for: channelId)
            let syncError: Error? = await withCheckedContinuation { cont in
                controller.synchronize { cont.resume(returning: $0) }
            }
            guard syncError == nil else { return false }
            return controller.messages.contains { $0.author.id == currentUserId }
        } catch {
            return false
        }
    }

    // MARK: - Channel

    func loadChannel(workOrderId: UUID, proId: UUID, clientId: UUID) async {
        guard let client = ChatViewModel.client else {
            errorMessage = "Chat not connected."
            return
        }
        isLoading = true

        let channelId = ChannelId(
            type: .messaging,
            id: "work_order_\(workOrderId.uuidString.lowercased())"
        )
        let members: Set<UserId> = [
            proId.uuidString.lowercased(),
            clientId.uuidString.lowercased()
        ]

        do {
            channelController = try client.channelController(
                createChannelWithId: channelId,
                members: members,
                isCurrentUserMember: true
            )
            channelController?.delegate = delegateProxy

            let syncError: Error? = await withCheckedContinuation { continuation in
                channelController?.synchronize { error in continuation.resume(returning: error) }
            }
            if let syncError {
                print("ChatViewModel: synchronize failed — \(syncError)")
                errorMessage = "Couldn't load chat: \(syncError.localizedDescription)"
                isLoading = false
                return
            }
            messages = Array(channelController?.messages ?? [])
                .filter { $0.type == .regular }
                .reversed()
        } catch {
            errorMessage = "Couldn't load chat: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func send(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        channelController?.createNewMessage(text: trimmed) { [weak self] result in
            if case .failure(let error) = result {
                Task { @MainActor in
                    self?.errorMessage = "Send failed: \(error.localizedDescription)"
                }
            }
        }
    }

    var currentUserId: String? {
        ChatViewModel.client?.currentUserId
    }
}

// MARK: - Delegate proxy (bridges Stream delegate → @Observable)

private class DelegateProxy: NSObject, ChatChannelControllerDelegate {
    weak var owner: ChatViewModel?

    func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        owner?.messages = Array(channelController.messages)
            .filter { $0.type == .regular }
            .reversed()
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {}
}
