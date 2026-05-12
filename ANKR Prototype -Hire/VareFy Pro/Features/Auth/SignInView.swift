import SwiftUI

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var navigateToSignUp = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Logo
                        VStack(spacing: 12) {
                            Image("VFYX")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                            Text("VareFy Pro")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text("Sign in to your account")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)

                        // Fields
                        VStack(spacing: 16) {
                            inputField(
                                label: "EMAIL",
                                placeholder: "you@example.com",
                                text: $email,
                                field: .email,
                                keyboardType: .emailAddress
                            )
                            inputField(
                                label: "PASSWORD",
                                placeholder: "••••••••",
                                text: $password,
                                field: .password,
                                isSecure: true
                            )
                        }

                        // Error
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Sign In
                        PrimaryButton(
                            title: isLoading ? "Signing in…" : "Sign In",
                            isEnabled: !email.isEmpty && !password.isEmpty && !isLoading
                        ) {
                            Task { await signIn() }
                        }

                        // Sign Up link
                        Button {
                            navigateToSignUp = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Have an invite code?")
                                    .foregroundStyle(.secondary)
                                Text("Create account")
                                    .foregroundStyle(Color.varefyProCyan)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationDestination(isPresented: $navigateToSignUp) {
                SignUpView()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundStyle(Color.varefyProCyan)
                }
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

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
