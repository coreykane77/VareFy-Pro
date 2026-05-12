import Foundation
import Supabase
import Observation

// Matches the public.profiles table in Supabase exactly
struct SupabaseProfile: Decodable {
    let id: UUID
    let role: String
    let display_name: String
    let email: String
    let phone: String?
    let avatar_storage_path: String?
    let stripe_connect_id: String?
    let stripe_connect_status: String?
    let approval_status: String?
    let is_verified: Bool
    let created_at: Date
}

@Observable
class AuthManager {

    var session: Session? = nil
    var profile: SupabaseProfile? = nil
    var isLoading: Bool = true

    var isAuthenticated: Bool { session != nil }
    var currentUserId: UUID? { session?.user.id }
    var role: String? { profile?.role }
    var isPendingApproval: Bool { profile?.approval_status == "pending" }

    init() {
        session = supabase.auth.currentSession
        Task {
            if session != nil {
                await fetchProfile()
                if let userId = session?.user.id {
                    await ChatViewModel.connect(
                        userId: userId.uuidString.lowercased(),
                        displayName: profile?.display_name
                    )
                }
            }
            isLoading = false
            await listenForAuthChanges()
        }
    }

    // MARK: - Auth State

    private func listenForAuthChanges() async {
        for await (event, newSession) in supabase.auth.authStateChanges {
            switch event {
            case .signedIn:
                session = newSession
                await fetchProfile()
                if let userId = newSession?.user.id {
                    await ChatViewModel.connect(
                        userId: userId.uuidString.lowercased(),
                        displayName: profile?.display_name
                    )
                }
            case .signedOut:
                session = nil
                profile = nil
                await ChatViewModel.disconnect()
            default:
                session = newSession
            }
        }
    }

    // MARK: - Sign Up

    func signUp(
        email: String,
        password: String,
        displayName: String,
        phone: String? = nil
    ) async throws {
        struct SignUpBody: Encodable {
            let email: String
            let password: String
            let display_name: String
            let phone: String?
        }

        let body = SignUpBody(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password,
            display_name: displayName.trimmingCharacters(in: .whitespaces),
            phone: phone?.isEmpty == false ? phone : nil
        )

        struct SignUpResponse: Decodable {
            let success: Bool?
            let error: String?
        }

        let response: SignUpResponse = try await supabase.functions
            .invoke("signup", options: FunctionInvokeOptions(body: body))

        if let error = response.error {
            throw AuthError.signUpFailed(error)
        }

        // Account created — sign in immediately to get session
        try await signIn(email: email, password: password)
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await supabase.auth.signIn(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            password: password
        )
        session = result
        await fetchProfile()
    }

    // MARK: - Sign Out

    func signOut() async throws {
        await ChatViewModel.disconnect()
        try await supabase.auth.signOut()
        session = nil
        profile = nil
    }

    // MARK: - Profile

    func fetchProfile() async {
        guard let userId = currentUserId else { return }
        do {
            profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
        } catch {
            print("AuthManager: failed to fetch profile — \(error)")
        }
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case signUpFailed(String)

    var errorDescription: String? {
        switch self {
        case .signUpFailed(let msg): return msg
        }
    }
}
