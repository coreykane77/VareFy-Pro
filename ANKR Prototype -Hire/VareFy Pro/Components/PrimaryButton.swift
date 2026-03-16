import SwiftUI

// MARK: - Highlight Row Style
// Applies a subtle pressed-state highlight to any tappable row or link.

struct HighlightRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.white.opacity(0.07) : Color.clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == HighlightRowStyle {
    static var highlightRow: HighlightRowStyle { HighlightRowStyle() }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void

    private var bg: Color {
        if !isEnabled { return Color.gray.opacity(0.3) }
        return isDestructive ? Color.red : Color.varefyProCyan
    }

    private var fg: Color {
        isEnabled ? .black : .gray
    }

    var body: some View {
        Button(action: {
            if isEnabled { Haptics.medium() }
            action()
        }) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isEnabled)
    }
}
