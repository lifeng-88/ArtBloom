import Foundation
import UIKit

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(AdSupport)
import AdSupport
#endif

#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

private let nativeAFHasObtainedAttributionKey = "artbloom.af_has_obtained_attribution"
private let nativeAFHasCompletedLoginKey = "artbloom.af_has_completed_login"
private let nativeAFAttributionJSONKey = "artbloom.af_attribution_json"
private let nativeAFAfIDKey = "artbloom.af_af_id"
private let nativeAFAdIDKey = "artbloom.af_ad_id"
private let nativeAFSourceKey = "artbloom.af_source"
private let nativeAFAttributionTimeoutSeconds: TimeInterval = 10

struct AFAttributionResult {
    var afId: String?
    var adId: String?
    var source: String?
    var attributionJson: String?

    static func timeoutFallback(reason: String = "timeout") -> AFAttributionResult {
        let timeoutJson = (try? JSONSerialization.data(withJSONObject: [
            "timeout": true,
            "reason": reason
        ]))
            .flatMap { String(data: $0, encoding: .utf8) }
        return AFAttributionResult(afId: nil, adId: nil, source: nil, attributionJson: timeoutJson)
    }

    var isTimeoutPlaceholder: Bool {
        guard let attributionJson,
              let data = attributionJson.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (object["timeout"] as? Bool) == true else {
            return false
        }
        return afId?.trimmedNonEmpty == nil
            && adId?.trimmedNonEmpty == nil
            && source?.trimmedNonEmpty == nil
    }

    var hasMeaningfulData: Bool {
        if isTimeoutPlaceholder { return false }
        return afId?.trimmedNonEmpty != nil
            || adId?.trimmedNonEmpty != nil
            || source?.trimmedNonEmpty != nil
            || attributionJson?.trimmedNonEmpty != nil
    }

    var loginParameters: [String: Any] {
        var params: [String: Any] = [:]
        if let source = source?.trimmedNonEmpty { params["source"] = source }
        if let afId = afId?.trimmedNonEmpty { params["afId"] = afId }
        if let adId = adId?.trimmedNonEmpty { params["adId"] = adId }
        if let attributionJson = enrichedAttributionJson?.trimmedNonEmpty {
            params["afAttributionJson"] = attributionJson
        }
        return params
    }

    /// 将 afId / adId 并入 conversion JSON，供 app_config 与 H5 回传。
    var enrichedAttributionJson: String? {
        var object: [String: Any] = [:]
        if let attributionJson,
           let data = attributionJson.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            object = parsed
        } else if let attributionJson = attributionJson?.trimmedNonEmpty {
            return attributionJson
        }
        if let afId = afId?.trimmedNonEmpty { object["af_id"] = afId }
        if let adId = adId?.trimmedNonEmpty { object["ad_id"] = adId }
        guard !object.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: object),
              let json = String(data: data, encoding: .utf8) else {
            return attributionJson
        }
        return json
    }
}

@MainActor
final class ArtBloomAFManager {
    static let shared = ArtBloomAFManager()

    private let defaults = UserDefaults.standard
    private var attributionResult: AFAttributionResult?
    private var attributionContinuation: CheckedContinuation<AFAttributionResult?, Never>?
    private var startedConfigurationKey: String?

    private init() {}

    func markLoginCompleted() {
        let wasFirstCompletedLogin = !defaults.bool(forKey: nativeAFHasCompletedLoginKey)
        defaults.set(true, forKey: nativeAFHasCompletedLoginKey)
        ArtBloomAFSDKBridge.logLogin()
        if wasFirstCompletedLogin {
            ArtBloomAFSDKBridge.logCompleteRegistration()
        }
    }

    func getAttributionForLogin() async -> AFAttributionResult? {
        getAttributionForLoginCached()
    }

    /// 统一 AF 初始化入口；`waitForAttribution` 为 true 时等待归因（首启 app_config 用）。
    func ensureReady(channelId: String?, waitForAttribution: Bool = false) async -> AFAttributionResult? {
        let effectiveChannel = effectiveChannel(channelId: channelId)
        #if DEBUG
        if ProcessInfo.processInfo.environment["SIMULATE_AF_TIMEOUT"] == "1" {
            return nil
        }
        #endif
        guard await configureAndStart(channelId: effectiveChannel) else {
            if ArtBloomBSideConfig.debugLogging {
                print("❌ [AF] ensureReady 失败：缺少 appleAppID/devKey，归因无法采集与回传 channel=\(effectiveChannel)")
            }
            return nil
        }
        if waitForAttribution {
            return await waitForAttributionOrTimeout()
        }
        return getAttributionForLoginCached()
    }

    func handleBecomeActive() {
        guard startedConfigurationKey != nil else { return }
        ArtBloomAFSDKBridge.start()
    }

    func handleOpenURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) {
        ArtBloomAFSDKBridge.handleOpen(url, options: options)
    }

    func handleUserActivity(_ userActivity: NSUserActivity) {
        ArtBloomAFSDKBridge.handleUserActivity(userActivity)
    }

    func prepareLoginAttribution(channelId: String?) async -> [String: Any] {
        if let cached = getAttributionForLoginCached(), cached.hasMeaningfulData {
            return cached.loginParameters
        }
        if let rawAttribution = await ensureReady(channelId: channelId, waitForAttribution: true),
           rawAttribution.hasMeaningfulData {
            return rawAttribution.loginParameters
        }
        let configured = await configureAndStart(channelId: effectiveChannel(channelId: channelId))
        let reason = configured ? "timeout" : "af_not_configured"
        return AFAttributionResult.timeoutFallback(reason: reason).loginParameters
    }

    func logEvent(
        channelId: String?,
        eventName: String,
        values: [String: Any]?
    ) async -> [String: Any] {
        let trimmedEventName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEventName.isEmpty else {
            return [
                "logged": false,
                "code": "INVALID_EVENT_NAME",
                "message": "Event name is required."
            ]
        }

        let effectiveChannel = effectiveChannel(channelId: channelId)
        guard await configureAndStart(channelId: effectiveChannel) else {
            return [
                "logged": false,
                "code": "AF_NOT_CONFIGURED",
                "message": "AppsFlyer is not configured. Check remote AF config or Info.plist keys."
            ]
        }

        let afValues = Self.normalizedEventValues(values)
        return await withCheckedContinuation { continuation in
            ArtBloomAFSDKBridge.logEvent(name: trimmedEventName, values: afValues.isEmpty ? nil : afValues) { result in
                Task { @MainActor in
                    switch result {
                    case let .success(response):
                        var payload: [String: Any] = [
                            "logged": true,
                            "eventName": trimmedEventName
                        ]
                        if !response.isEmpty {
                            payload["response"] = response
                        }
                        continuation.resume(returning: payload)
                    case let .failure(error):
                        continuation.resume(returning: [
                            "logged": false,
                            "code": "AF_LOG_EVENT_FAILED",
                            "message": error.localizedDescription,
                            "eventName": trimmedEventName
                        ])
                    }
                }
            }
        }
    }

    func setAttribution(afId: String?, adId: String?, source: String?, attributionJson: String?) {
        let result = AFAttributionResult(
            afId: afId,
            adId: adId,
            source: source,
            attributionJson: attributionJson
        )
        attributionResult = result
        if let afId = afId?.trimmedNonEmpty { defaults.set(afId, forKey: nativeAFAfIDKey) }
        if let adId = adId?.trimmedNonEmpty { defaults.set(adId, forKey: nativeAFAdIDKey) }
        if let source = source?.trimmedNonEmpty { defaults.set(source, forKey: nativeAFSourceKey) }
        if let attributionJson = result.enrichedAttributionJson?.trimmedNonEmpty {
            defaults.set(attributionJson, forKey: nativeAFAttributionJSONKey)
        }
        // 仅在拿到有效归因时永久标记，失败/超时可下次重试。
        if result.hasMeaningfulData {
            defaults.set(true, forKey: nativeAFHasObtainedAttributionKey)
        }
        resumeAttributionWait(with: result)
    }

    /// conversion 失败或等待超时：释放等待方，但不永久标记，下次可重试。
    func handleAttributionUnavailable(reason: String) {
        if ArtBloomBSideConfig.debugLogging {
            print("⚠️ [AF] attribution unavailable (\(reason))，可下次重试")
        }
        resumeAttributionWait(with: getAttributionForLoginCached())
    }

    private func resumeAttributionWait(with result: AFAttributionResult?) {
        guard let continuation = attributionContinuation else { return }
        attributionContinuation = nil
        continuation.resume(returning: result)
    }

    private static func normalizedEventValues(_ values: [String: Any]?) -> [String: Any] {
        guard let values else { return [:] }
        var result: [String: Any] = [:]
        for (key, value) in values {
            let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedKey.isEmpty, let normalized = normalizedEventValue(value) else { continue }
            result[trimmedKey] = normalized
        }
        return result
    }

    private static func normalizedEventValue(_ value: Any) -> Any? {
        switch value {
        case let string as String: return string
        case let number as NSNumber: return number
        case let bool as Bool: return bool
        case let int as Int: return int
        case let double as Double: return double
        case let dict as [String: Any]:
            let nested = normalizedEventValues(dict)
            return nested.isEmpty ? nil : nested
        case let array as [Any]:
            let normalized = array.compactMap { normalizedEventValue($0) }
            return normalized.isEmpty ? nil : normalized
        default:
            return nil
        }
    }

    private func waitForAttributionOrTimeout() async -> AFAttributionResult? {
        // 旧版本失败路径可能留下“已获取”但缓存为空；允许重试。
        if defaults.bool(forKey: nativeAFHasObtainedAttributionKey) {
            if let cached = getAttributionForLoginCached(), cached.hasMeaningfulData {
                return cached
            }
            defaults.set(false, forKey: nativeAFHasObtainedAttributionKey)
        }

        return await withCheckedContinuation { continuation in
            attributionContinuation = continuation
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(nativeAFAttributionTimeoutSeconds * 1_000_000_000))
                ArtBloomAFManager.shared.timeoutAttribution()
            }
        }
    }

    private func timeoutAttribution() {
        handleAttributionUnavailable(reason: "timeout_\(Int(nativeAFAttributionTimeoutSeconds))s")
    }

    private func getAttributionForLoginCached() -> AFAttributionResult? {
        if let attributionResult { return attributionResult }
        let afId = defaults.string(forKey: nativeAFAfIDKey)
        let adId = defaults.string(forKey: nativeAFAdIDKey)
        let source = defaults.string(forKey: nativeAFSourceKey)
        let json = defaults.string(forKey: nativeAFAttributionJSONKey)
        if afId?.trimmedNonEmpty != nil || adId?.trimmedNonEmpty != nil || source?.trimmedNonEmpty != nil || json?.trimmedNonEmpty != nil {
            return AFAttributionResult(afId: afId, adId: adId, source: source, attributionJson: json)
        }
        return nil
    }

    private func configureAndStart(channelId: String) async -> Bool {
        // 无论远程 AF 配置是否可用，都先完成 ATT（审核要求：追踪前必须弹窗）。
        await ArtBloomATTManager.requestAuthorizationIfNeeded()

        let appleAppID = await ArtBloomAFRemoteConfig.shared.getAppleAppID(channelId: channelId)
        let appsFlyerDevKey = await ArtBloomAFRemoteConfig.shared.getAppsFlyerDevKey(channelId: channelId)

        guard let appleAppID, let appsFlyerDevKey else {
            if ArtBloomBSideConfig.debugLogging {
                print("[AF] Missing AF config for channel=\(channelId)")
            }
            return false
        }

        let configurationKey = "\(appleAppID)|\(appsFlyerDevKey)"
        if startedConfigurationKey == configurationKey {
            return true
        }

        let customerUserID = await ArtBloomDeviceManager.shared.getDeviceId()
        ArtBloomAFSDKBridge.configure(
            appleAppID: appleAppID,
            appsFlyerDevKey: appsFlyerDevKey,
            customerUserID: customerUserID
        )
        ArtBloomAFSDKBridge.start()
        startedConfigurationKey = configurationKey
        if ArtBloomBSideConfig.debugLogging {
            print("✅ [AF] started channel=\(channelId) appID=\(appleAppID) adId=\(Self.advertisingIdentifierIfAuthorized() ?? "nil")")
        }
        return true
    }

    nonisolated static func advertisingIdentifierIfAuthorized() -> String? {
        if #available(iOS 14, *) {
            guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return nil }
        }
        let idfa = ASIdentifierManager.shared().advertisingIdentifier
        let value = idfa.uuidString
        guard value != "00000000-0000-0000-0000-000000000000" else { return nil }
        return value
    }

    private func effectiveChannel(channelId: String?) -> String {
        channelId?.trimmedNonEmpty ?? ArtBloomBSideConfig.channel
    }
}

enum ArtBloomAFSDKBridge {
    static func configure(appleAppID: String, appsFlyerDevKey: String, customerUserID: String) {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().appleAppID = appleAppID
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerLib.shared().customerUserID = customerUserID
        AppsFlyerLib.shared().delegate = ArtBloomAFDelegateWrapper.shared
        #else
        _ = appleAppID
        _ = appsFlyerDevKey
        _ = customerUserID
        #endif
    }

    static func start() {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().start()
        #endif
    }

    static func logCompleteRegistration() {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().logEvent("af_complete_registration", withValues: [
            "af_registration_method": "device"
        ])
        #endif
    }

    static func logLogin() {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().logEvent("af_login", withValues: [
            "af_login_method": "device"
        ])
        #endif
    }

    static func logEvent(
        name: String,
        values: [String: Any]?,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().logEvent(
            name: name,
            values: values,
            completionHandler: { response, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                completion(.success(response ?? [:]))
            }
        )
        #else
        _ = name
        _ = values
        completion(.success([:]))
        #endif
    }

    static func handleOpen(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().handleOpen(url, options: options)
        #endif
    }

    static func handleUserActivity(_ userActivity: NSUserActivity) {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        #endif
    }
}

#if canImport(AppsFlyerLib)
private final class ArtBloomAFDelegateWrapper: NSObject, AppsFlyerLibDelegate {
    static let shared = ArtBloomAFDelegateWrapper()

    private override init() {
        super.init()
    }

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let afId = AppsFlyerLib.shared().getAppsFlyerUID()
        let adId = ArtBloomAFManager.advertisingIdentifierIfAuthorized()
        var payload: [String: Any] = [:]
        for (key, value) in conversionInfo {
            payload[String(describing: key)] = value
        }
        if !afId.isEmpty { payload["af_id"] = afId }
        if let adId { payload["ad_id"] = adId }
        let attributionJson = (try? JSONSerialization.data(withJSONObject: payload))
            .flatMap { String(data: $0, encoding: .utf8) }
        let source = conversionInfo["media_source"] as? String
        Task { @MainActor in
            ArtBloomAFManager.shared.setAttribution(
                afId: afId,
                adId: adId,
                source: source,
                attributionJson: attributionJson
            )
        }
    }

    func onConversionDataFail(_ error: Error) {
        Task { @MainActor in
            ArtBloomAFManager.shared.handleAttributionUnavailable(
                reason: error.localizedDescription
            )
        }
    }
}
#endif

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
