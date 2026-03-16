import SwiftUI

enum SenderType {
    case hire, client, system
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: SenderType
    let timestamp: Date
}

// MARK: - Seeded history

private let h: TimeInterval = 3600
private let m: TimeInterval = 60

private func ago(_ seconds: TimeInterval) -> Date {
    Date().addingTimeInterval(-seconds)
}

private let seededChatHistory: [ChatMessage] = [
    ChatMessage(
        text: "Work Order confirmed and assigned. Scheduled window accepted. Please review job notes before driving.",
        sender: .system,
        timestamp: ago(9 * h + 12 * m)
    ),
    ChatMessage(
        text: "Hi! Before you come — the gate code is 4892. Park in the driveway.",
        sender: .client,
        timestamp: ago(8 * h + 48 * m)
    ),
    ChatMessage(
        text: "Got it, thanks for the heads up. I'll be there right on time.",
        sender: .hire,
        timestamp: ago(8 * h + 44 * m)
    ),
    ChatMessage(
        text: "Also — there's a storage unit in the back, please don't block it.",
        sender: .client,
        timestamp: ago(8 * h + 41 * m)
    ),
    ChatMessage(
        text: "Noted, will keep it clear.",
        sender: .hire,
        timestamp: ago(8 * h + 39 * m)
    ),
    ChatMessage(
        text: "Integrity Reminder: Two pre-work site photos are required before the billing timer can start. Capture from the job entry point.",
        sender: .system,
        timestamp: ago(1 * h + 22 * m)
    ),
    ChatMessage(
        text: "Still coming today? Just making sure everything's on track.",
        sender: .client,
        timestamp: ago(58 * m)
    ),
    ChatMessage(
        text: "Yep, heading your way now. Should be there in about 20.",
        sender: .hire,
        timestamp: ago(55 * m)
    ),
    ChatMessage(
        text: "Perfect! I'll be inside — just knock when you arrive.",
        sender: .client,
        timestamp: ago(53 * m)
    ),
    ChatMessage(
        text: "✓ Pre-work photos uploaded (2/2). Integrity gate passed. Billing timer has started.",
        sender: .system,
        timestamp: ago(28 * m)
    ),
    ChatMessage(
        text: "How's it going so far? Any issues?",
        sender: .client,
        timestamp: ago(14 * m)
    ),
    ChatMessage(
        text: "All good — making solid progress.",
        sender: .hire,
        timestamp: ago(11 * m)
    ),
    ChatMessage(
        text: "Great! No rush, take your time.",
        sender: .client,
        timestamp: ago(9 * m)
    ),
]

// MARK: - ChatView

struct ChatView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM

    @State private var messages: [ChatMessage] = seededChatHistory
    @State private var inputText = ""
    @State private var isClientTyping = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    private let clientReplies = [
        "Sounds good!",
        "Okay, thanks!",
        "Got it, appreciate it.",
        "Perfect, thank you!",
        "Great, I'll be nearby if you need anything.",
        "Thanks for the update!",
        "Okay, no problem at all.",
        "Awesome, thanks!",
        "Works for me!",
        "Understood, thank you."
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                clientHeader

                Divider()
                    .background(Color.white.opacity(0.08))

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if isClientTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isClientTyping) {
                        if isClientTyping {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.08))

                inputBar
            }
        }
        .navigationTitle(order?.clientName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
        .onAppear {
            workOrderVM.currentChatOrderId = orderId
            workOrderVM.markChatRead(for: orderId)
        }
        .onDisappear {
            if workOrderVM.currentChatOrderId == orderId {
                workOrderVM.currentChatOrderId = nil
            }
        }
    }

    // MARK: - Subviews

    private var clientHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.varefyProCyan.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(order.map { clientInitials($0.clientName) } ?? "?")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.varefyProCyan)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(order?.clientName ?? "Client")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(order?.serviceTitle ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appCard)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(4)
                .tint(Color.varefyProCyan)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? Color.varefyProCyan.opacity(0.3)
                                     : Color.varefyProCyan)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(text: trimmed, sender: .hire, timestamp: Date()))
        inputText = ""

        let replyText = clientReplies.randomElement() ?? "Sounds good!"
        let delay = Double.random(in: 1.2...2.4)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            isClientTyping = true
            try? await Task.sleep(for: .seconds(delay))
            isClientTyping = false
            messages.append(ChatMessage(text: replyText, sender: .client, timestamp: Date()))
            if workOrderVM.currentChatOrderId != orderId {
                workOrderVM.markChatUnread(for: orderId)
            }
        }
    }

    private func clientInitials(_ name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.sender {
        case .hire:
            hireBubble
        case .client:
            clientBubble
        case .system:
            systemCard
        }
    }

    private var hireBubble: some View {
        HStack {
            Spacer(minLength: 60)
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.varefyProCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Text(message.timestamp.formattedAsTime())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var clientBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Text(message.timestamp.formattedAsTime())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 60)
        }
    }

    private var systemCard: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.varefyProCyan.opacity(0.4))
                .frame(width: 2)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.varefyProCyan)
                    Text("VareFy Pro")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.varefyProCyan)
                        .tracking(1)
                }
                Text(message.text)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.75))
                Text(message.timestamp.formattedAsTime())
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.varefyProCyan.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.varefyProCyan.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.9)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 60)
        }
        .onAppear { phase = 0 }
    }
}
