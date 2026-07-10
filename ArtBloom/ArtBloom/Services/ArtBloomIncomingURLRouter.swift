import Foundation
import UIKit

/// 统一处理深链与支付回调，避免 AppDelegate 与 SwiftUI `.onOpenURL` 重复触发。
@MainActor
enum ArtBloomIncomingURLRouter {
    private static var recentURLs: [String: Date] = [:]
    private static let dedupeWindow: TimeInterval = 1.5

    static func handleOpenURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        guard markIfNew(url) else {
            if ArtBloomBSideConfig.debugLogging {
                print("🔗 [URLRouter] deduped open url=\(url.absoluteString)")
            }
            return
        }

        ArtBloomAFManager.shared.handleOpenURL(url, options: options)
        if ArtBloomPaymentRedirectReturnURL.matches(url) {
            ArtBloomPaymentCallbackManager.shared.handle(url: url)
        }
    }

    static func handleUserActivity(_ userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL, !markIfNew(url) {
            if ArtBloomBSideConfig.debugLogging {
                print("🔗 [URLRouter] deduped userActivity url=\(url.absoluteString)")
            }
            return
        }

        ArtBloomAFManager.shared.handleUserActivity(userActivity)
    }

    private static func markIfNew(_ url: URL) -> Bool {
        let key = url.absoluteString
        let now = Date()
        if let last = recentURLs[key], now.timeIntervalSince(last) < dedupeWindow {
            return false
        }
        recentURLs[key] = now
        recentURLs = recentURLs.filter { now.timeIntervalSince($0.value) < dedupeWindow * 2 }
        return true
    }
}
