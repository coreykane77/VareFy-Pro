import SwiftUI

struct SignUpView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @FocusState private var focusedField: Field?

    enum Field { case name, email, phone, password, confirmPassword }

    private var canSubmit: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        !isLoading
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image("VFYX")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Text("Apply to join VareFy Pro")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text("Your application will be reviewed before you can access jobs.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Personal info
                    VStack(spacing: 14) {
                        inputField(label: "FULL NAME", placeholder: "Your name", text: $displayName, field: .name)
                        inputField(label: "EMAIL", placeholder: "you@example.com", text: $email, field: .email, keyboardType: .emailAddress)
                        inputField(label: "PHONE (optional)", placeholder: "+1 (555) 000-0000", text: $phone, field: .phone, keyboardType: .phonePad)
                    }

                    // Password
                    VStack(spacing: 14) {
                        inputField(label: "PASSWORD", placeholder: "Minimum 6 characters", text: $password, field: .password, isSecure: true)
                        inputField(label: "CONFIRM PASSWORD", placeholder: "Re-enter password", text: $confirmPassword, field: .confirmPassword, isSecure: true)

                        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    PrimaryButton(
                        title: isLoading ? "Submitting…" : "Submit Application",
                        isEnabled: canSubmit
                    ) {
                        Task { await signUp() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .foregroundStyle(Color.varefyProCyan)
            }
        }
    }

    @ViewBuilder
    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .focused($focusedField, equals: field)
            .padding(14)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authManager.signUp(
                email: email,
                password: password,
                displayName: displayName,
                phone: phone.isEmpty ? nil : phone
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
