import SwiftUI

@main
struct VareFyProApp: App {
    @State private var workOrderVM  = WorkOrderViewModel()
    @State private var walletVM     = WalletViewModel()
    @State private var profileVM    = ProfileViewModel()
    @State private var settingsVM   = AppSettingsViewModel()
    @State private var servicesVM   = ServicesViewModel()

    var body: some Scene {
        WindowGroup {
            HireHomeView()
                .environment(workOrderVM)
                .environment(walletVM)
                .environment(profileVM)
                .environment(settingsVM)
                .environment(servicesVM)
                .preferredColorScheme(.dark)
        }
    }
}
