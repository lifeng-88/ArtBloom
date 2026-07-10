import Foundation

// MARK: - API Models

struct ArtBloomAppConfigRequest {
    let devId: String
    let source: String?
    let channel: String?
    let version: String
    let afAttributionJson: String?

    func queryItems() -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "dev_id", value: devId),
            URLQueryItem(name: "version", value: version)
        ]
        if let source, !source.isEmpty {
            items.append(URLQueryItem(name: "source", value: source))
        }
        if let channel, !channel.isEmpty {
            items.append(URLQueryItem(name: "channel", value: channel))
        }
        if let afAttributionJson, !afAttributionJson.isEmpty {
            items.append(URLQueryItem(name: "af_attribution_json", value: afAttributionJson))
        }
        return items
    }
}

struct ArtBloomAppConfigResponse: Decodable {
    let type: Int?
    let h5Url: String?
    let webUrl: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case type
        case rechargePresentationType = "recharge_presentation_type"
        case h5Url = "h5_url"
        case webUrl = "web_url"
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = Self.decodeFlexibleInt(from: container, forKey: .type)
            ?? Self.decodeFlexibleInt(from: container, forKey: .rechargePresentationType)
        h5Url = try? container.decode(String.self, forKey: .h5Url)
        webUrl = try? container.decode(String.self, forKey: .webUrl)
        url = try? container.decode(String.self, forKey: .url)
    }

    var preferredWebURLString: String? {
        for candidate in [h5Url, webUrl, url] {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private static func decodeFlexibleInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let string = try? container.decode(String.self, forKey: key), let value = Int(string) { return value }
        if let value = try? container.decode(Int32.self, forKey: key) { return Int(value) }
        return nil
    }
}

// MARK: - Persistence

enum ArtBloomAppConfigPersistence {
    static let presentationTypeKey = "artbloom.v1.app_config.presentation_type"
    static let surfaceWebURLKey = "artbloom.v1.app_config.surface_web_url"
    static let fetchSucceededKey = "artbloom.v1.app_config.fetch_succeeded"
    static let lastRemoteRefreshKey = "artbloom.v1.app_config.last_remote_refresh"

    static func migrateIfNeeded() {}

    static var hasPersistedSuccessfulFetch: Bool {
        UserDefaults.standard.bool(forKey: fetchSucceededKey)
    }

    static func readPersistedPresentationType(defaultValue: Int = 1) -> Int {
        guard let raw = UserDefaults.standard.object(forKey: presentationTypeKey) as? Int else {
            return defaultValue
        }
        return raw == 1 || raw == 2 ? raw : defaultValue
    }

    static func readPersistedSurfaceWebURL() -> String? {
        let raw = UserDefaults.standard.string(forKey: surfaceWebURLKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? nil : raw
    }

    static func persistSuccessfulPresentationType(_ value: Int, webURL: String? = nil) {
        guard value == 1 || value == 2 else { return }
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: presentationTypeKey)
        defaults.set(true, forKey: fetchSucceededKey)
        if let webURL {
            let trimmed = webURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                defaults.set(trimmed, forKey: surfaceWebURLKey)
            }
        }
    }
}

// MARK: - Service

enum ArtBloomAppConfigService {
    static func fetchAppConfig(request: ArtBloomAppConfigRequest) async -> Result<ArtBloomAppConfigResponse, Error> {
        guard let baseURL = ArtBloomBSideConfig.apiBaseURL else {
            return .failure(ArtBloomAppConfigError.apiNotConfigured)
        }

        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/app_config"),
            resolvingAgainstBaseURL: false
        ) else {
            return .failure(ArtBloomAppConfigError.invalidURL)
        }
        components.queryItems = request.queryItems()

        guard let url = components.url else {
            return .failure(ArtBloomAppConfigError.invalidURL)
        }

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        urlRequest.setValue("ArtBloom/1.0", forHTTPHeaderField: "User-Agent")

        if ArtBloomBSideConfig.debugLogging {
            logRequest(url: url, request: request)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                if ArtBloomBSideConfig.debugLogging {
                    print("❌ [ArtBloomAppConfig] 无效响应类型 url=\(url.absoluteString)")
                }
                return .failure(ArtBloomAppConfigError.badStatus(statusCode: nil))
            }

            if ArtBloomBSideConfig.debugLogging {
                logResponse(url: url, statusCode: http.statusCode, data: data)
            }

            guard (200...299).contains(http.statusCode) else {
                return .failure(ArtBloomAppConfigError.badStatus(statusCode: http.statusCode))
            }
            let decoded = try JSONDecoder().decode(ArtBloomAppConfigResponse.self, from: data)
            if ArtBloomBSideConfig.debugLogging {
                print("✅ [ArtBloomAppConfig] 解码成功 type=\(decoded.type.map(String.init) ?? "nil") webURL=\(decoded.preferredWebURLString ?? "nil")")
            }
            return .success(decoded)
        } catch let error as DecodingError {
            if ArtBloomBSideConfig.debugLogging {
                print("❌ [ArtBloomAppConfig] 解码失败: \(error)")
            }
            return .failure(error)
        } catch {
            if ArtBloomBSideConfig.debugLogging {
                print("❌ [ArtBloomAppConfig] 网络失败: \(error.localizedDescription)")
            }
            return .failure(error)
        }
    }

    private static func logRequest(url: URL, request: ArtBloomAppConfigRequest) {
        print("🌐 [ArtBloomAppConfig] ========== 请求 ==========")
        print("🌐 [ArtBloomAppConfig] GET \(url.absoluteString)")
        print("🌐 [ArtBloomAppConfig] dev_id=\(request.devId)")
        print("🌐 [ArtBloomAppConfig] version=\(request.version)")
        print("🌐 [ArtBloomAppConfig] channel=\(request.channel ?? "nil")")
        print("🌐 [ArtBloomAppConfig] source=\(request.source ?? "nil")")
        if let json = request.afAttributionJson {
            let preview = json.count > 240 ? String(json.prefix(240)) + "…(\(json.count) chars)" : json
            print("🌐 [ArtBloomAppConfig] af_attribution_json=\(preview)")
        } else {
            print("🌐 [ArtBloomAppConfig] af_attribution_json=nil")
        }
        print("🌐 [ArtBloomAppConfig] ==========================")
    }

    private static func logResponse(url: URL, statusCode: Int, data: Data) {
        print("📡 [ArtBloomAppConfig] ========== 响应 ==========")
        print("📡 [ArtBloomAppConfig] Status: \(statusCode)")
        print("📡 [ArtBloomAppConfig] URL: \(url.absoluteString)")
        if let body = String(data: data, encoding: .utf8) {
            print("📡 [ArtBloomAppConfig] Body: \(body)")
        } else {
            print("📡 [ArtBloomAppConfig] Body: <non-utf8, \(data.count) bytes>")
        }
        print("📡 [ArtBloomAppConfig] ==========================")
    }
}

enum ArtBloomAppConfigError: LocalizedError {
    case apiNotConfigured
    case invalidURL
    case badStatus(statusCode: Int?)

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: return "API base URL is not configured"
        case .invalidURL: return "Invalid app config URL"
        case .badStatus(let code):
            if let code { return "App config request failed (HTTP \(code))" }
            return "App config request failed"
        }
    }
}
