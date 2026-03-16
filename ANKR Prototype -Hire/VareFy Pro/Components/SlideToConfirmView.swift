import SwiftUI

struct SlideToConfirmView: View {
    let label: String
    let onConfirm: () -> Void

    @State private var offset: CGFloat = 0
    private let knobSize: CGFloat = 52
    private let trackHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - knobSize - 8
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.varefyProCard)
                    .overlay(
                        Text(label)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary.opacity(0.6))
                    )

                // Progress fill
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.varefyProCyan.opacity(0.3))
                    .frame(width: offset + knobSize)

                // Knob
                Circle()
                    .fill(Color.varefyProCyan)
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Image(systemName: "chevron.right.2")
                            .foregroundStyle(.black)
                            .fontWeight(.bold)
                    )
                    .offset(x: 4 + offset)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                let newOffset = min(max(0, val.translation.width), maxOffset)
                                // Tick at 50% and 85% thresholds
                                let oldPct = offset / maxOffset
                                let newPct = newOffset / maxOffset
                                if (oldPct < 0.5 && newPct >= 0.5) || (oldPct < 0.85 && newPct >= 0.85) {
                                    Haptics.selection()
                                }
                                offset = newOffset
                            }
                            .onEnded { _ in
                                if offset >= maxOffset * 0.85 {
                                    Haptics.success()
                                    onConfirm()
                                } else {
                                    Haptics.light()
                                }
                                withAnimation(.spring()) { offset = 0 }
                            }
                    )
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
    }
}
