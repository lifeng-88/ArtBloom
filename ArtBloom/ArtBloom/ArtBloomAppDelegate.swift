import UIKit
import UserNotifications

final class ArtBloomAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = ArtBloomPushNotificationDelegate.shared

        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            ArtBloomPushManager.shared.captureLaunchPayload(userInfo, source: "launchOptions")
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            ArtBloomAFManager.shared.handleBecomeActive()
        }
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Task { @MainActor in
            ArtBloomIncomingURLRouter.handleOpenURL(url, options: options)
        }
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        Task { @MainActor in
            ArtBloomIncomingURLRouter.handleUserActivity(userActivity)
        }
        return userActivity.webpageURL != nil
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        ArtBloomPushManager.shared.updateDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        ArtBloomPushManager.shared.updateRegistrationFailure(error)
    }
}
