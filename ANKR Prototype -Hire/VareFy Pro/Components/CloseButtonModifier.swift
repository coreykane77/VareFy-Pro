import SwiftUI

// X button — dismisses all the way to root (used by work-order flow screens)
struct CloseButtonModifier: ViewModifier {
    @Environment(\.dismissToRoot) private var dismissToRoot

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismissToRoot()
                    } label: {
                        xButtonLabel
                    }
                }
            }
    }
}

// X button — pops one level (used by drawer-launched screens so drawer re-opens)
struct PopButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        xButtonLabel
                    }
                }
            }
    }
}

private var xButtonLabel: some View {
    Image(systemName: "xmark")
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(Color(UIColor { tc in
            tc.userInterfaceStyle == .dark ? .white : .label
        }))
        .frame(width: 30, height: 30)
        .background(Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.15)
                : UIColor.systemGray4
        }))
        .clipShape(Circle())
}

extension View {
    func closeButton() -> some View {
        modifier(CloseButtonModifier())
    }

    func popButton() -> some View {
        modifier(PopButtonModifier())
    }
}
