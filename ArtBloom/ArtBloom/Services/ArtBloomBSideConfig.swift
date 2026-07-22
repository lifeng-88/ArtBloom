import Foundation
import WebKit

enum ArtBloomBSideConfig {
    /// 代码内显式 B 面入口（优先级最高）。
    static let entryURLString = ""

    /// 默认 H5 落地页。
    static let defaultLandingBase = "https://glowpeach.icu/h5/landing"

    private static let infoURLKey = "ART_BLOOM_B_SIDE_URL"
    private static let apiBaseURLKey = "APIBaseURL"
    private static let resBaseURLKey = "ResBaseURL"
    private static let channelInfoKey = "AppChannel"
    static let defaultChannel = "IOS10071"
    /// DEBUG 本地 H5 默认 RuntimeConfig 地址（渠道 888886）。
    static let debugDefaultCfgURL = "https://raw.githubusercontent.com/wwqxs/TXDNF/refs/heads/main/888886.json"

    /// H5 通过 `?cfg=` 拉取的 RuntimeConfig JSON。
    static var runtimeConfigURL: String {
        #if DEBUG
        return debugResolvedCfgURL()
        #else
        let base = effectiveResBaseURL
        return "\(base)/config/\(channel).json"
        #endif
    }

    #if DEBUG
    static func debugResolvedCfgURL() -> String {
        ProcessInfo.processInfo.environment["APP_CFG_URL"]?.trimmedNonEmpty ?? debugDefaultCfgURL
    }
    #endif

    /// `getAppInfo` 返回的 API 基址字符串。
    static var effectiveAPIBaseURL: String? {
        apiBaseURL?.absoluteString
    }

    static var buildConfigurationLabel: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    /// AF 静态配置与 H5 RuntimeConfig 基址（`{ResBaseURL}/config/{channel}.json`）。
    static var effectiveResBaseURL: String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: resBaseURLKey) as? String,
           let trimmed = raw.trimmedNonEmpty,
           !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) {
            return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        }
        if let api = apiBaseURL, let host = api.host, let scheme = api.scheme {
            return "\(scheme)://\(host)"
        }
        if let landing = URL(string: defaultLandingBase), let host = landing.host, let scheme = landing.scheme {
            return "\(scheme)://\(host)"
        }
        return "https://res.glowpeach.icu"
    }

    static var channel: String {
        #if DEBUG
        if let env = ProcessInfo.processInfo.environment["APP_CHANNEL"]?.trimmedNonEmpty {
            return env
        }
        #endif
        if let plist = Bundle.main.object(forInfoDictionaryKey: channelInfoKey) as? String,
           let trimmed = plist.trimmedNonEmpty {
            return trimmed
        }
        return defaultChannel
    }

    static var apiBaseURL: URL? {
        normalizedURL(from: Bundle.main.object(forInfoDictionaryKey: apiBaseURLKey) as? String)
    }

    /// DEBUG：保留开关供后续调试入口使用；启动不再自动进 B 面。
    static var shouldAutoOpenDebugBSide: Bool {
        #if DEBUG
        guard debugEnvURL() != nil else { return false }
        return ProcessInfo.processInfo.environment["AUTO_OPEN_B_SIDE"] != "0"
        #else
        return false
        #endif
    }

    /// 远端 app_config → 本地缓存 → Info.plist → 代码常量 → Bundle 演示页。
    static func resolveURL(remoteURLString: String?) -> URL? {
        #if DEBUG
        if let debugURL = debugEnvURL() { return debugURL }
        #endif
        if let url = normalizedURL(from: remoteURLString) { return url }
        if let cached = ArtBloomAppConfigPersistence.readPersistedSurfaceWebURL(),
           let url = normalizedURL(from: cached) {
            return url
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: infoURLKey) as? String,
           let url = normalizedURL(from: raw) {
            return landingURLWithChannel(base: url)
        }
        if let value = entryURLString.trimmedNonEmpty, let url = URL(string: value) {
            return landingURLWithChannel(base: url)
        }
        if let bundled = bundledURL { return bundled }
        return defaultLandingURL()
    }

    static var bundledURL: URL? {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "BSide")
            ?? Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web/BSide")
    }

    static var isConfigured: Bool {
        resolveURL(remoteURLString: nil) != nil || debugEnvURL() != nil || apiBaseURL != nil
    }

    static var appDisplayName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "ArtBloom"
    }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var privacyURL: URL? {
        URL(string: "https://lifeng-88.github.io/jyshare-legal/artbloom-privacy-policy.html")
    }

    static var supportURL: URL? {
        URL(string: "https://lifeng-88.github.io/jyshare-legal/artbloom-support.html")
    }

    static var debugLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static var webViewInspectable: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static func configureWebViewInspectability(_ webView: WKWebView) {
        if #available(iOS 16.4, *) {
            webView.isInspectable = webViewInspectable
        }
    }

    static func configureWebView(_ webView: WKWebView) {
        configureWebViewInspectability(webView)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.keyboardDismissMode = .none
    }

    static func urlAppendingLaunchParams(_ url: URL, channel: String, deviceId: String) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        let cfgValue = runtimeConfigURL
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "channel" || $0.name == "did" || $0.name == "cfg" }
        if isHTTPSConfigURL(cfgValue) {
            items.append(URLQueryItem(name: "cfg", value: cfgValue))
        }
        items.append(URLQueryItem(name: "channel", value: channel))
        items.append(URLQueryItem(name: "did", value: deviceId))
        components.queryItems = items
        return components.url ?? url
    }

    /// PeachGen H5 仅接受 `https://` 的 cfg 参数（见 runtimeConfigLoader.ts）。
    private static func isHTTPSConfigURL(_ value: String) -> Bool {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return url.scheme?.lowercased() == "https"
    }

    static func debugEnvURL() -> URL? {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["APP_H5_URL"]?.trimmedNonEmpty,
           let url = URL(string: raw) {
            return url
        }
        return nil
        #else
        return nil
        #endif
    }

    private static func defaultLandingURL() -> URL? {
        guard let base = normalizedURL(from: defaultLandingBase) else { return nil }
        return landingURLWithChannel(base: base)
    }

    private static func landingURLWithChannel(base: URL) -> URL {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            return base
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "channel" }
        items.append(URLQueryItem(name: "channel", value: channel))
        components.queryItems = items
        return components.url ?? base
    }

    private static func normalizedURL(from raw: String?) -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) else { return nil }
        return URL(string: trimmed)
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
