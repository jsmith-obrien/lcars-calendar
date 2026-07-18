import UIKit

/// Only exists to answer the system's orientation question dynamically —
/// see OrientationLock.swift for why.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.shared.preference.mask
    }
}
