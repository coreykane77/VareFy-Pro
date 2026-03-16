import SwiftUI

struct AppSettingsView: View {
    @Environment(AppSettingsViewModel.self) private var settingsVM

    var body: some View {
        @Bindable var settings = settingsVM

        ZStack {
            Color(settingsVM.isDarkMode ? UIColor.systemBackground.resolvedColor(with: .init(userInterfaceStyle: .dark)) : UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            List {
                Section {
                    Toggle(isOn: $settings.isDarkMode) {
                        HStack(spacing: 12) {
                            Image(systemName: settingsVM.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundStyle(settingsVM.isDarkMode ? Color.varefyProCyan : Color.varefyProGold)
                                .frame(width: 20)
                            Text("Dark Mode")
                        }
                    }
                    .tint(Color.varefyProCyan)
                } header: {
                    Text("Appearance")
                }

                Section {
                    ForEach(NavAppPreference.allCases, id: \.self) { app in
                        Button {
                            if app.isInstalled || app == .appleMaps {
                                Haptics.selection()
                                settingsVM.preferredNavApp = app
                            }
                        } label: {
                            navAppRow(
                                app: app,
                                isSelected: settingsVM.preferredNavApp == app,
                                isDisabled: app != .appleMaps && !app.isInstalled
                            )
                        }
                        .buttonStyle(.highlightRow)
                    }
                } header: {
                    Text("Navigation App")
                } footer: {
                    let notInstalled = NavAppPreference.allCases.filter { $0 != .appleMaps && !$0.isInstalled }
                    if !notInstalled.isEmpty {
                        Text(notInstalled.map(\.rawValue).joined(separator: " and ") + " not installed on this device.")
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Haptics.light()
                        if let url = URL(string: "https://www.varefy.app") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        settingsRowContent(icon: "questionmark.circle.fill", label: "Help & Support", color: .gray)
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: NavRoute.termsOfService) {
                        settingsRowContent(icon: "doc.text.fill", label: "Terms of Service", color: .gray)
                    }
                    .simultaneousGesture(TapGesture().onEnded { Haptics.light() })
                    NavigationLink(value: NavRoute.privacyPolicy) {
                        settingsRowContent(icon: "lock.shield.fill", label: "Privacy Policy", color: .gray)
                    }
                    .simultaneousGesture(TapGesture().onEnded { Haptics.light() })
                } header: {
                    Text("About")
                }

            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .toolbarColorScheme(settingsVM.isDarkMode ? .dark : .light, for: .navigationBar)
        .popButton()
    }

    @ViewBuilder
    private func settingsRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRowContent(icon: icon, label: label, color: color)
        }
        .buttonStyle(.highlightRow)
    }

    @ViewBuilder
    private func settingsRowContent(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private func navAppRow(app: NavAppPreference, isSelected: Bool, isDisabled: Bool) -> some View {
        HStack(spacing: 12) {
            Group {
                if app == .appleMaps {
                    Image(systemName: "apple.logo")
                        .foregroundStyle(.primary)
                        .frame(width: 20, height: 20)
                } else {
                    if app == .waze {
                        Image("3")
                            .resizable()
                            .scaledToFit()
                            .colorInvert()
                            .frame(width: 20, height: 20)
                    } else {
                        Image("4")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
            }

            Text(app.rawValue)
                .foregroundStyle(isDisabled ? .tertiary : .primary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.varefyProCyan)
            }

            if isDisabled {
                Text("Not installed")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .opacity(isDisabled ? 0.45 : 1)
    }
}
