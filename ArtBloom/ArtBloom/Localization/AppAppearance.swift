import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable, Equatable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    static func load() -> AppAppearance {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let appearance = AppAppearance(rawValue: raw) else {
            return .system
        }
        return appearance
    }

    func persist() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }

    private static let storageKey = "artbloom.app_appearance"
}
