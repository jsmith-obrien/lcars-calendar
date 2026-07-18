import SwiftUI
import UIKit

enum OrientationPreference: String, CaseIterable, Identifiable, Equatable {
    case landscapeLeft
    case landscapeRight

    var id: String { rawValue }

    var mask: UIInterfaceOrientationMask {
        switch self {
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        }
    }

    var label: String {
        switch self {
        case .landscapeLeft: return "LANDSCAPE LEFT"
        case .landscapeRight: return "LANDSCAPE RIGHT"
        }
    }
}

/// Lets the wall orientation be switched from the Config screen instead of
/// requiring a rebuild every time the iPad moves to a different spot on the
/// fridge with the charging cable routed out a different side.
///
/// Info.plist (`project.yml`) still declares BOTH landscape orientations as
/// the outer bound — the system will never allow an orientation missing
/// from there, no matter what this class returns. `AppDelegate` is what
/// narrows that down to exactly one at a time, so a physical tilt still
/// can't flip it; only changing `preference` here can.
@MainActor
final class OrientationLock: ObservableObject {
    static let shared = OrientationLock()

    private static let defaultsKey = "com.lcarscalendar.orientationPreference"

    @Published var preference: OrientationPreference {
        didSet { UserDefaults.standard.set(preference.rawValue, forKey: Self.defaultsKey) }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.defaultsKey)
        self.preference = OrientationPreference(rawValue: stored ?? "") ?? .landscapeRight
    }

    /// Nudges the system to re-check `AppDelegate`'s orientation mask and
    /// rotate immediately, rather than waiting for the next relaunch or the
    /// next physical rotation event to notice the preference changed.
    func applyImmediately() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        if #available(iOS 16.0, *) {
            scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: preference.mask))
        } else {
            // No forced-rotation API before iOS 16 that isn't a fragile,
            // easy-to-get-backwards private-API trick. The preference is
            // still saved via didSet above and takes effect on next launch,
            // or the next time the device is physically rotated.
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
