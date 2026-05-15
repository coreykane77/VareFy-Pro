import SwiftUI

extension Color {
    static let varefyProCyan    = Color(red: 0.05, green: 0.78, blue: 0.87)
    static let varefyProDark    = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let varefyProCard    = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let varefyProGold    = Color(red: 0.94, green: 0.75, blue: 0.04)
    static let varefyProLime    = Color(red: 0.56, green: 0.90, blue: 0.06)
    static let varefyProOverlay = Color.black.opacity(0.75)

    /// Adaptive screen background — varefyProDark in dark mode, systemGray5 in light mode.
    /// Using systemGray5 (#E5E5EA) rather than systemGroupedBackground (#F2F2F7) so
    /// white cards have visible contrast against the background in light mode.
    static let appBackground = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
            : UIColor.systemGray5
    })

    /// Adaptive card background — varefyProCard in dark mode, secondary grouped bg in light mode.
    static let appCard = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
            : UIColor.secondarySystemGroupedBackground
    })

    /// Adaptive navigation bar background.
    static let appNavBar = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
            : UIColor.systemBackground
    })
}

extension Double {
    func formattedAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

extension TimeInterval {
    func formattedAsElapsed() -> String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        let s = Int(self) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

// MARK: - BOSS Badge

struct BOSSBadge: View {
    var height: CGFloat = 32
    var body: some View {
        Image("Boss logo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}

extension View {
    func doneKeyboardToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
    }
}

extension Date {
    func formattedAsTime() -> String {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if cal.isDateInToday(self) {
            return "Today · " + formatter.string(from: self)
        } else if cal.isDateInTomorrow(self) {
            return "Tomorrow · " + formatter.string(from: self)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
    }

    func formattedAsDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}
