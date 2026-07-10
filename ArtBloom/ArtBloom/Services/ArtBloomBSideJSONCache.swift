import CryptoKit
import Foundation

final class ArtBloomBSideJSONCache {
    static let shared = ArtBloomBSideJSONCache()

    private let fileManager = FileManager.default
    private let directory: URL
    private let defaultTTL: TimeInterval = 24 * 60 * 60
    private let maxFiles = 120

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directory = caches.appendingPathComponent("ArtBloomBSideJSONCache", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func value(namespace: String, key: String) -> [String: Any] {
        let fileURL = fileURL(namespace: namespace, key: key)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return ["cached": false]
        }

        guard let data = try? Data(contentsOf: fileURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            try? fileManager.removeItem(at: fileURL)
            return ["cached": false]
        }

        let now = Date().timeIntervalSince1970
        let expiresAt = object["expiresAt"] as? TimeInterval ?? 0
        if expiresAt > 0, now > expiresAt {
            try? fileManager.removeItem(at: fileURL)
            return ["cached": false]
        }

        return [
            "cached": true,
            "updatedAt": object["updatedAt"] ?? NSNull(),
            "value": object["value"] ?? NSNull()
        ]
    }

    func setValue(namespace: String, key: String, value: Any, ttlSeconds: TimeInterval?) -> Bool {
        guard !key.isEmpty, JSONSerialization.isValidJSONObject(["value": value]) else { return false }

        let now = Date().timeIntervalSince1970
        let ttl = ttlSeconds ?? defaultTTL
        let object: [String: Any] = [
            "updatedAt": now,
            "expiresAt": ttl > 0 ? now + ttl : 0,
            "value": value
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            try data.write(to: fileURL(namespace: namespace, key: key), options: .atomic)
            trimIfNeeded()
            return true
        } catch {
            return false
        }
    }

    func clearAll() -> Int {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return 0
        }
        var removed = 0
        for file in files {
            if (try? fileManager.removeItem(at: file)) != nil {
                removed += 1
            }
        }
        return removed
    }

    private func fileURL(namespace: String, key: String) -> URL {
        let raw = "\(namespace)__\(key)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined() + ".json"
        return directory.appendingPathComponent(name)
    }

    private func trimIfNeeded() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ), files.count > maxFiles else { return }

        let sorted = files.sorted { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhsDate < rhsDate
        }

        for file in sorted.prefix(files.count - maxFiles) {
            try? fileManager.removeItem(at: file)
        }
    }
}
