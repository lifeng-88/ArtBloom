import Foundation
import UIKit

actor ArtBloomDeviceManager {
    static let shared = ArtBloomDeviceManager()

    private static let legacyDeviceIdKey = "artbloom.device_id"

    private init() {}

    func getDeviceId() async -> String {
        await resolvedKeychainDeviceId()
    }

    func getAppVersion() async -> String {
        await MainActor.run {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        }
    }

    private func resolvedKeychainDeviceId() async -> String {
        let keychain = ArtBloomKeychainManager.shared
        if let saved = await keychain.load(key: ArtBloomKeychainKey.devId),
           !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return saved
        }

        if let legacy = UserDefaults.standard.string(forKey: Self.legacyDeviceIdKey),
           !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? await keychain.save(key: ArtBloomKeychainKey.devId, value: legacy)
            UserDefaults.standard.removeObject(forKey: Self.legacyDeviceIdKey)
            return legacy
        }

        let newId = await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }

        do {
            try await keychain.save(key: ArtBloomKeychainKey.devId, value: newId)
        } catch {
            UserDefaults.standard.set(newId, forKey: Self.legacyDeviceIdKey)
            if ArtBloomBSideConfig.debugLogging {
                print("⚠️ [DeviceManager] Keychain save failed, fallback to UserDefaults devId")
            }
        }
        return newId
    }
}
