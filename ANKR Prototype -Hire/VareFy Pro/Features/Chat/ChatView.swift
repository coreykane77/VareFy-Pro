import SwiftUI
import StreamChat

struct ChatView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(AuthManager.self) private var authManager

    @State private var chatVM = ChatViewModel()
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if chatVM.isLoading {
                    Spacer()
                    ProgressView().tint(Color.varefyProCyan)
                    Spacer()
                } else if let errMsg = chatVM.errorMessage {
                    Spacer()
                    errorState(errMsg)
                    Spacer()
                } else {
                    messageList
                }

                inputBar
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .onAppear {
            workOrderVM.markChatRead(for: orderId)
        }
        .task {
            guard let order = order,
                  let proId = authManager.currentUserId else { return }
            await chatVM.loadChannel(
                workOrderId: order.id,
                proId: proId,
                clientId: order.clientId
            )
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if chatVM.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(chatVM.messages, id: \.id) { message in
                            if let order = order {
                                messageBubble(message, clientId: order.clientId)
                                    .id(message.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: chatVM.messages.count) {
                if let lastId = chatVM.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage, clientId: UUID) -> some View {
        let role = senderRole(for: message, clientId: clientId)
        let isOwn = role == .pro

        HStack(alignment: .bottom, spacing: 8) {
            if isOwn { Spacer(minLength: 60) }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
                if !isOwn {
                    senderLabel(for: role)
                }

                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isOwn ? Color.black : Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleColor(for: role))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(isOwn ? .trailing : .leading, 4)
            }

            if !isOwn { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private func senderLabel(for role: SenderRole) -> some View {
        switch role {
        case .client:
            Text("Client")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        case .agent:
            HStack(spacing: 4) {
                Image(systemName: "shield.fill")
                    .font(.caption2)
                Text("VareFy Agent")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.purple)
            .padding(.leading, 4)
        case .pro:
            EmptyView()
        }
    }

    private func bubbleColor(for role: SenderRole) -> Color {
        switch role {
        case .pro:    return Color.varefyProCyan
        case .client: return Color.appCard
        case .agent:  return Color.purple.opacity(0.25)
        }
    }

    private func senderRole(for message: ChatMessage, clientId: UUID) -> SenderRole {
        if message.isSentByCurrentUser { return .pro }
        if message.author.id == clientId.uuidString.lowercased() { return .client }
        return .agent
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $draft, axis: .vertical)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .lineLimit(1...5)
                .focused($inputFocused)

            Button {
                let text = draft
                draft = ""
                chatVM.send(text: text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        draft.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.gray.opacity(0.5)
                            : Color.varefyProCyan
                    )
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.easeInOut(duration: 0.15), value: draft.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, Constants.bottomBarHeight + 10)
        .background(Color.appNavBar)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.varefyProCyan.opacity(0.4))
            Text("No messages yet")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("Start the conversation with your client.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    @ViewBuilder
    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private enum SenderRole {
    case pro, client, agent
}
