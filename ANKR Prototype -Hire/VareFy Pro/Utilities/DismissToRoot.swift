import SwiftUI

private struct DismissToRootKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissToRoot: () -> Void {
        get { self[DismissToRootKey.self] }
        set { self[DismissToRootKey.self] = newValue }
    }
}
