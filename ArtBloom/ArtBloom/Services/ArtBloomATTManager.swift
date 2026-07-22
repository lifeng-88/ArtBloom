import Foundation
import UIKit

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

/// 在应用进入前台且窗口就绪后请求 ATT，确保审核员在最新 iPadOS/iOS 上能看到弹窗。
/// 必须在 AppsFlyer start / 任何追踪数据采集之前完成。
@MainActor
enum ArtBloomATTManager {
    private static var didRequestThisLaunch = false

    /// 等待 `UIApplication` 变为 active 后再请求；已决定状态则立即返回。
    static func requestAuthorizationIfNeeded() async {
        guard #available(iOS 14, *) else { return }

        let status = ATTrackingManager.trackingAuthorizationStatus
        if status != .notDetermined {
            if ArtBloomBSideConfig.debugLogging {
                print("📱 [ATT] already determined status=\(status.rawValue)")
            }
            return
        }

        await waitUntilApplicationActive()

        // 再读一次：等待期间系统可能已变更。
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        guard !didRequestThisLaunch else { return }
        didRequestThisLaunch = true

        // 给首帧 / key window 一点时间，避免 iPadOS 上静默失败。
        try? await Task.sleep(nanoseconds: 400_000_000)

        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        guard UIApplication.shared.applicationState == .active else {
            if ArtBloomBSideConfig.debugLogging {
                print("⚠️ [ATT] skip request: application not active")
            }
            didRequestThisLaunch = false
            return
        }

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<ATTrackingManager.AuthorizationStatus, Never>) in
            ATTrackingManager.requestTrackingAuthorization { newStatus in
                continuation.resume(returning: newStatus)
            }
        }

        if ArtBloomBSideConfig.debugLogging {
            print("📱 [ATT] request finished status=\(result.rawValue)")
        }
    }

    private static func waitUntilApplicationActive(timeoutSeconds: TimeInterval = 8) async {
        if UIApplication.shared.applicationState == .active { return }

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if UIApplication.shared.applicationState == .active { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
