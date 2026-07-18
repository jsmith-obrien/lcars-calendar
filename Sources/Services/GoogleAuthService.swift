import Foundation
import GoogleSignIn
import UIKit

/// Thin wrapper around GIDSignIn so the rest of the app never touches the SDK
/// directly. Read-only calendar scope only — write-back is a possible future
/// phase, not implemented here.
@MainActor
final class GoogleAuthService {
    static let shared = GoogleAuthService()

    private static let calendarReadOnlyScope = "https://www.googleapis.com/auth/calendar.readonly"

    private init() {}

    var isSignedIn: Bool {
        GIDSignIn.sharedInstance.currentUser != nil
    }

    var hasPreviousSignIn: Bool {
        GIDSignIn.sharedInstance.hasPreviousSignIn()
    }

    var currentUserEmail: String? {
        GIDSignIn.sharedInstance.currentUser?.profile?.email
    }

    /// Restores a session saved in the keychain from a previous launch.
    /// Should only be called once at startup, never mid-session (per Google's
    /// own docs) — interactive re-sign-in goes through `signIn()` instead.
    func restorePreviousSignIn() async throws {
        _ = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
    }

    func signIn() async throws {
        guard let presenter = Self.topViewController() else {
            throw AuthError.noPresenter
        }
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presenter,
            hint: nil,
            additionalScopes: [Self.calendarReadOnlyScope]
        )
        // Google's consent screen lets a user complete sign-in while declining
        // an individual additional scope — this is a real, reachable path, not
        // hypothetical. Without this check the failure only surfaces later as
        // an opaque 403 from the Calendar API, with no way for the user to
        // tell that's what happened.
        guard result.user.grantedScopes?.contains(Self.calendarReadOnlyScope) == true else {
            throw AuthError.calendarScopeDenied
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    /// Returns a valid access token, refreshing first if the cached one is
    /// stale — the SDK only actually calls the network when the cached token
    /// is close to expiring, otherwise this returns instantly.
    func freshAccessToken() async throws -> String? {
        guard let user = GIDSignIn.sharedInstance.currentUser else { return nil }
        let refreshed = try await user.refreshTokensIfNeeded()
        return refreshed.accessToken.tokenString
    }

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    enum AuthError: LocalizedError {
        case noPresenter
        case calendarScopeDenied

        var errorDescription: String? {
            switch self {
            case .noPresenter:
                return "No screen available to present Google sign-in."
            case .calendarScopeDenied:
                return "Calendar access was not granted. Please sign in again and allow calendar access."
            }
        }
    }
}
