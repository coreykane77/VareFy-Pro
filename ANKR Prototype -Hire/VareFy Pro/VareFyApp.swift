import SwiftUI

@main
struct VareFyProApp: App {
    @State private var authManager   = AuthManager()
    @State private var workOrderVM   = WorkOrderViewModel()
    @State private var walletVM      = WalletViewModel()
    @State private var profileVM     = ProfileViewModel()
    @State private var settingsVM    = AppSettingsViewModel()
    @State private var servicesVM    = ServicesViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    LaunchScreenView()
                } else if authManager.isAuthenticated {
                    if authManager.isPendingApproval {
                        PendingApprovalView()
                    } else {
                        HireHomeView()
                            .environment(workOrderVM)
                            .environment(walletVM)
                            .environment(profileVM)
                            .environment(settingsVM)
                            .environment(servicesVM)
                    }
                } else {
                    SignInView()
                }
            }
            .environment(authManager)
            .preferredColorScheme(.dark)
        }
    }
}
