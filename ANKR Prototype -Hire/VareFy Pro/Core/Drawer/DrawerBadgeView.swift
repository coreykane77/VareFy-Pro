import SwiftUI

/// Badge indicator used in the drawer menu rows.
/// `.chat` renders a chat-bubble shape (matches Messages row in design).
/// `.ops`  renders a rounded rect (matches Local Ops row in design).
struct DrawerBadgeView: View {
    enum Style { case chat, ops }

    let text: String
    let style: Style

    var body: some View {
        switch style {
        case .chat:
            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.varefyProCyan)
                .clipShape(ChatBubbleShape())

        case .ops:
            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.varefyProCyan)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// A simple chat-bubble shape: rounded rect with a small tail on the bottom-left.
private struct ChatBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 6
        let tailW: CGFloat = 6
        let tailH: CGFloat = 5

        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height - tailH),
            cornerSize: CGSize(width: r, height: r)
        )
        // tail pointing down-left
        p.move(to: CGPoint(x: r, y: rect.height - tailH))
        p.addLine(to: CGPoint(x: r, y: rect.height))
        p.addLine(to: CGPoint(x: r + tailW, y: rect.height - tailH))
        p.closeSubpath()
        return p
    }
}

