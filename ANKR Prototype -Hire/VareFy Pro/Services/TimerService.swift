import Foundation

// Billing timer logic lives in WorkOrderViewModel using Swift async Task.
// This file serves as a stub/placeholder per the spec folder structure.
enum TimerService {
    static func formattedElapsed(_ seconds: Double) -> String {
        seconds.formattedAsElapsed()
    }
}
