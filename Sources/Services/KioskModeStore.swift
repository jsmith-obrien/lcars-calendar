import Foundation
import UIKit

/// Controls whether the app automatically requests a Guided Access session
/// on launch/foreground — a well-documented public API (`UIAccessibility.
/// requestGuidedAccessSession`) that lets an app "lock itself" into
/// single-app mode without the user manually triple-clicking the side
/// button. This does NOT require Supervised Mode or a device wipe — it only
/// requires Guided Access to be turned on once in Settings > Accessibility
/// > Guided Access. That one-time toggle is a device setting, not something
/// this app can flip on the user's behalf.
///
/// This does not, by itself, make the app auto-launch after the iPad fully
/// reboots — that piece genuinely does require Supervised Mode via Apple
/// Configurator, a bigger and more consequential step (typically means
/// erasing the device first if it wasn't already supervised).
@MainActor
final class KioskModeStore: ObservableObject {
    static let shared = KioskModeStore()

    private static let defaultsKey = "com.joshuasmithobrien.lcarscalendar.kioskModeEnabled"

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.defaultsKey) }
    }

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.defaultsKey)
    }

    func requestSessionIfEnabled() {
        guard isEnabled else { return }
        UIAccessibility.requestGuidedAccessSession(enabled: true) { _ in }
    }
}
