import Foundation

/// B 面展示控制：冷启动缓存 type=2 进 B 面，否则 A 面；`/v1/app_config` 返回 type=2 时持久化并进入 B 面。
@Observable
@MainActor
final class ArtBloomBSideManager {
    static let shared = ArtBloomBSideManager()

    enum Phase: Equatable {
        case loading
        case native
        case web(URL)
    }

    private(set) var phase: Phase
    private(set) var isBootstrapComplete: Bool
    private(set) var surfaceWebURL: URL?

    private var bootstrapInFlight: Task<Void, Never>?
    private var remoteRefreshInFlight: Task<Void, Never>?

    var isShowingWeb: Bool {
        if case .web = phase { return true }
        return false
    }

    #if DEBUG
    var canSwitchToBSide: Bool {
        ArtBloomBSideConfig.resolveURL(remoteURLString: ArtBloomAppConfigPersistence.readPersistedSurfaceWebURL()) != nil
            || ArtBloomBSideConfig.debugEnvURL() != nil
    }
    #endif

    private init() {
        ArtBloomAppConfigPersistence.migrateIfNeeded()
        if ArtBloomAppConfigPersistence.hasPersistedSuccessfulFetch {
            let cachedType = ArtBloomAppConfigPersistence.readPersistedPresentationType()
            let webURLString = ArtBloomAppConfigPersistence.readPersistedSurfaceWebURL()
            if cachedType == 2, let url = ArtBloomBSideConfig.resolveURL(remoteURLString: webURLString) {
                surfaceWebURL = url
                phase = .web(url)
            } else {
                surfaceWebURL = cachedType == 2
                    ? ArtBloomBSideConfig.resolveURL(remoteURLString: webURLString)
                    : nil
                phase = .native
            }
            isBootstrapComplete = true
        } else {
            phase = .native
            isBootstrapComplete = false
            surfaceWebURL = nil
        }
    }

    func bootstrapFromRemote() async {
        if ArtBloomAppConfigPersistence.hasPersistedSuccessfulFetch {
            let cached = ArtBloomAppConfigPersistence.readPersistedPresentationType()
            updateSurfaceConfig(type: cached, webURLString: ArtBloomAppConfigPersistence.readPersistedSurfaceWebURL())
            if !isBootstrapComplete { isBootstrapComplete = true }
            if ArtBloomBSideConfig.debugLogging {
                let label = cached == 2 ? "H5" : "A"
                print("✅ [ArtBloomBSideManager] app_config 使用本地缓存 type=\(cached) → 冷启动 \(label) 面")
            }
            Task(priority: .utility) { await self.refreshIfNeeded() }
            return
        }

        guard ArtBloomBSideConfig.apiBaseURL != nil else {
            if ArtBloomBSideConfig.debugLogging {
                print("⚠️ [ArtBloomBSideManager] APIBaseURL 未配置，跳过 app_config，保持 A 面")
            }
            phase = .native
            isBootstrapComplete = true
            return
        }

        if let inFlight = bootstrapInFlight {
            await inFlight.value
            return
        }

        let task = Task { await self.performFirstLaunchBootstrap() }
        bootstrapInFlight = task
        await task.value
        bootstrapInFlight = nil
    }

    func refreshIfNeeded(minInterval: TimeInterval = 300, force: Bool = false) async {
        guard ArtBloomBSideConfig.apiBaseURL != nil else { return }

        if !ArtBloomAppConfigPersistence.hasPersistedSuccessfulFetch {
            await bootstrapFromRemote()
            return
        }

        if !force {
            let last = UserDefaults.standard.double(forKey: ArtBloomAppConfigPersistence.lastRemoteRefreshKey)
            guard last <= 0 || Date().timeIntervalSince1970 - last >= minInterval else { return }
        }

        if let inFlight = remoteRefreshInFlight {
            await inFlight.value
            return
        }

        let task = Task { await self.fetchAppConfigFromNetwork() }
        remoteRefreshInFlight = task
        await task.value
        remoteRefreshInFlight = nil
    }

    func switchToBSide() async {
        guard let url = await resolveBSideURL() else { return }
        surfaceWebURL = url
        phase = .web(url)
        ArtBloomAppConfigPersistence.persistSuccessfulPresentationType(2, webURL: url.absoluteString)
    }

    func switchToNative() {
        phase = .native
        ArtBloomAppConfigPersistence.persistSuccessfulPresentationType(1)
    }

    func showSurfaceA() {
        switchToNative()
    }

    private func performFirstLaunchBootstrap() async {
        phase = .native
        if ArtBloomBSideConfig.debugLogging {
            print("📱 [ArtBloomBSideManager] app_config 首启：默认 A 面，等待 AF 后请求")
        }
        let channel = ArtBloomBSideConfig.channel
        // 直接使用 ensureReady 返回值，避免再读缓存导致归因被丢弃。
        let attribution = await ArtBloomAFManager.shared.ensureReady(
            channelId: channel,
            waitForAttribution: true
        )
        let result = await requestAppConfig(channel: channel, attribution: attribution)
        await applyAppConfigResponse(result)
        isBootstrapComplete = true
    }

    private func fetchAppConfigFromNetwork() async {
        let channel = ArtBloomBSideConfig.channel
        let rawAttribution = await ArtBloomAFManager.shared.getAttributionForLogin()
        let result = await requestAppConfig(channel: channel, attribution: rawAttribution)
        if case .success = result {
            UserDefaults.standard.set(
                Date().timeIntervalSince1970,
                forKey: ArtBloomAppConfigPersistence.lastRemoteRefreshKey
            )
        }
        await applyAppConfigResponse(result)
    }

    private func requestAppConfig(
        channel: String,
        attribution raw: AFAttributionResult?
    ) async -> Result<ArtBloomAppConfigResponse, Error> {
        let attribution: AFAttributionResult
        if let raw, raw.hasMeaningfulData {
            attribution = raw
        } else if let raw, raw.isTimeoutPlaceholder {
            attribution = raw
        } else {
            attribution = AFAttributionResult.timeoutFallback(reason: "af_unavailable")
        }
        let deviceId = await ArtBloomDeviceManager.shared.getDeviceId()
        let version = await ArtBloomDeviceManager.shared.getAppVersion()
        let request = ArtBloomAppConfigRequest(
            devId: deviceId,
            source: attribution.source,
            channel: channel,
            version: version,
            afId: attribution.afId,
            adId: attribution.adId,
            afAttributionJson: attribution.enrichedAttributionJson
        )
        if ArtBloomBSideConfig.debugLogging {
            print("📱 [ArtBloomBSideManager] 请求 /v1/app_config channel=\(channel) version=\(version) source=\(attribution.source ?? "nil") afId=\(attribution.afId ?? "nil") adId=\(attribution.adId ?? "nil") jsonChars=\(attribution.enrichedAttributionJson?.count ?? 0)")
        }
        return await ArtBloomAppConfigService.fetchAppConfig(request: request)
    }

    private func applyAppConfigResponse(_ result: Result<ArtBloomAppConfigResponse, Error>) async {
        switch result {
        case .success(let response):
            if let type = response.type, type == 1 || type == 2 {
                applyPresentationType(type, webURLString: response.preferredWebURLString, persist: true)
                if ArtBloomBSideConfig.debugLogging {
                    let label = type == 2 ? "H5" : "A"
                    print("✅ [ArtBloomBSideManager] app_config 成功 type=\(type) → \(label) 面，已持久化")
                }
            } else if !ArtBloomAppConfigPersistence.hasPersistedSuccessfulFetch {
                applyFirstLaunchFailure(reason: "invalid_type(\(response.type.map(String.init) ?? "nil"))")
            } else if ArtBloomBSideConfig.debugLogging {
                print("⚠️ [ArtBloomBSideManager] app_config 刷新返回无效 type=\(response.type.map(String.init) ?? "nil")，保留本地")
            }
        case .failure(let error):
            if !ArtBloomAppConfigPersistence.hasPersistedSuccessfulFetch {
                applyFirstLaunchFailure(reason: error.localizedDescription)
            } else if ArtBloomBSideConfig.debugLogging {
                let cached = ArtBloomAppConfigPersistence.readPersistedPresentationType()
                print("⚠️ [ArtBloomBSideManager] app_config 刷新失败(\(error.localizedDescription))，保留本地 type=\(cached)")
            }
        }
    }

    private func updateSurfaceConfig(type: Int, webURLString: String?, persist: Bool = false) {
        if type == 2 {
            surfaceWebURL = ArtBloomBSideConfig.resolveURL(remoteURLString: webURLString)
        } else {
            surfaceWebURL = nil
        }

        if persist {
            ArtBloomAppConfigPersistence.persistSuccessfulPresentationType(type, webURL: webURLString)
        }
    }

    private func applyPresentationType(_ type: Int, webURLString: String?, persist: Bool) {
        if type == 2 {
            let url = ArtBloomBSideConfig.resolveURL(remoteURLString: webURLString)
            surfaceWebURL = url
            if let url {
                phase = .web(url)
            } else {
                phase = .native
            }
        } else {
            surfaceWebURL = nil
            phase = .native
        }

        if persist {
            ArtBloomAppConfigPersistence.persistSuccessfulPresentationType(type, webURL: webURLString)
        }
    }

    private func applyFirstLaunchFailure(reason: String) {
        phase = .native
        surfaceWebURL = nil
        if ArtBloomBSideConfig.debugLogging {
            print("❌ [ArtBloomBSideManager] app_config 首启失败(\(reason))，进 A 面且不保存")
        }
    }

    private func resolveBSideURL() async -> URL? {
        let deviceId = await ArtBloomDeviceManager.shared.getDeviceId()
        let channel = ArtBloomBSideConfig.channel

        let baseURL: URL?
        #if DEBUG
        if let debugURL = ArtBloomBSideConfig.debugEnvURL() {
            baseURL = debugURL
        } else {
            baseURL = ArtBloomBSideConfig.resolveURL(
                remoteURLString: ArtBloomAppConfigPersistence.readPersistedSurfaceWebURL()
            )
        }
        #else
        baseURL = ArtBloomBSideConfig.resolveURL(
            remoteURLString: ArtBloomAppConfigPersistence.readPersistedSurfaceWebURL()
        )
        #endif

        guard let baseURL else { return nil }
        return ArtBloomBSideConfig.urlAppendingLaunchParams(baseURL, channel: channel, deviceId: deviceId)
    }
}
