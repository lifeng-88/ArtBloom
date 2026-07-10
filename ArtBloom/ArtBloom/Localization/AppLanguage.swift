import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    case system
    case en
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"

    var id: String { rawValue }

    var locale: Locale? {
        switch self {
        case .system: return nil
        case .en: return Locale(identifier: "en")
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .zhHant: return Locale(identifier: "zh-Hant")
        }
    }

    /// 对应 `.lproj` 目录名；`system` 返回 nil 表示跟随系统 Bundle。
    var bundleLanguageCode: String? {
        switch self {
        case .system: return nil
        case .en: return "en"
        case .zhHans: return "zh-Hans"
        case .zhHant: return "zh-Hant"
        }
    }

    static func load() -> AppLanguage {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let language = AppLanguage(rawValue: raw) else {
            return .system
        }
        return language
    }

    func persist() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }

    private static let storageKey = "artbloom.app_language"
}
