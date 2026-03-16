import UIKit

enum Haptics {
    // General taps, navigation, minor interactions
    static func light()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    // Significant actions — button presses, confirmations
    static func medium()    { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    // Major transitions — start work, complete, arrive
    static func heavy()     { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    // Crisp tick — toggles, segmented controls, selections
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    // Positive completion — job confirmed, payout submitted
    static func success()   { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    // Caution — leaving radius, locked action attempted
    static func warning()   { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    // Failure — error state
    static func error()     { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
