import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct StoredUserProfile: Codable, Equatable {
    var displayName: String
    var avatarFilename: String?
    var bio: String

    init(displayName: String = "", avatarFilename: String? = nil, bio: String = "") {
        self.displayName = displayName
        self.avatarFilename = avatarFilename
        self.bio = bio
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decode(String.self, forKey: .displayName)
        avatarFilename = try container.decodeIfPresent(String.self, forKey: .avatarFilename)
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
    }
}

struct SavedArtwork: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var imageFilename: String
    var createdAt: Date
    var isDraft: Bool
    var isFavorite: Bool
    var favoritedAt: Date?

    init(
        id: UUID,
        title: String,
        subtitle: String,
        imageFilename: String,
        createdAt: Date,
        isDraft: Bool,
        isFavorite: Bool,
        favoritedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageFilename = imageFilename
        self.createdAt = createdAt
        self.isDraft = isDraft
        self.isFavorite = isFavorite
        self.favoritedAt = favoritedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        imageFilename = try container.decode(String.self, forKey: .imageFilename)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isDraft = try container.decode(Bool.self, forKey: .isDraft)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        favoritedAt = try container.decodeIfPresent(Date.self, forKey: .favoritedAt)
    }
}

struct ArtworkSavePayload {
    let previewImage: UIImage
    let baseImage: UIImage
    let session: ArtworkSession
    let title: String
    let subtitle: String
    let isDraft: Bool
}

@Observable
final class ArtworkStore {
    private(set) var items: [SavedArtwork] = []

    private let metadataKey = "artbloom.artworks.metadata"
    private let jpegQuality: CGFloat = 0.88

    private var artworksDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Artworks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        load()
    }

    func imageURL(for artwork: SavedArtwork) -> URL {
        artworksDirectory.appendingPathComponent(artwork.imageFilename)
    }

    func baseImageURL(for artwork: SavedArtwork) -> URL {
        artworksDirectory.appendingPathComponent(baseFilename(for: artwork.id))
    }

    func strokesURL(for artwork: SavedArtwork) -> URL {
        artworksDirectory.appendingPathComponent(strokesFilename(for: artwork.id))
    }

    func strokesURL(for id: UUID) -> URL {
        artworksDirectory.appendingPathComponent(strokesFilename(for: id))
    }

    @discardableResult
    func save(_ payload: ArtworkSavePayload) -> Bool {
        let id = UUID()
        let previewFilename = "\(id.uuidString).jpg"
        let previewURL = artworksDirectory.appendingPathComponent(previewFilename)
        let baseURL = artworksDirectory.appendingPathComponent(baseFilename(for: id))
        let strokesURL = artworksDirectory.appendingPathComponent(strokesFilename(for: id))

        guard let previewData = payload.previewImage.jpegData(compressionQuality: jpegQuality),
              let baseData = payload.baseImage.jpegData(compressionQuality: jpegQuality),
              let strokesData = try? JSONEncoder().encode(payload.session) else { return false }

        do {
            try previewData.write(to: previewURL, options: .atomic)
            try baseData.write(to: baseURL, options: .atomic)
            try strokesData.write(to: strokesURL, options: .atomic)

            let artwork = SavedArtwork(
                id: id,
                title: payload.title,
                subtitle: payload.subtitle,
                imageFilename: previewFilename,
                createdAt: Date(),
                isDraft: payload.isDraft,
                isFavorite: false
            )
            items.insert(artwork, at: 0)
            persist()
            return true
        } catch {
            try? FileManager.default.removeItem(at: previewURL)
            try? FileManager.default.removeItem(at: baseURL)
            try? FileManager.default.removeItem(at: strokesURL)
            return false
        }
    }

    func loadSession(for id: UUID) -> ArtworkSession? {
        let url = strokesURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let session = try? JSONDecoder().decode(ArtworkSession.self, from: data) else { return nil }
        return session
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite.toggle()
        items[index].favoritedAt = items[index].isFavorite ? Date() : nil
        persist()
    }

    func setFavorite(_ id: UUID, favorite: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard items[index].isFavorite != favorite else { return }
        items[index].isFavorite = favorite
        items[index].favoritedAt = favorite ? Date() : nil
        persist()
    }

    func promoteDraft(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isDraft = false
        persist()
    }

    @discardableResult
    func updateTitle(_ id: UUID, title: String) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        items[index].title = trimmed
        persist()
        return true
    }

    func artwork(with id: UUID) -> SavedArtwork? {
        items.first { $0.id == id }
    }

    @discardableResult
    func updateArtwork(
        id: UUID,
        previewImage: UIImage,
        baseImage: UIImage,
        session: ArtworkSession
    ) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }),
              let previewData = previewImage.jpegData(compressionQuality: jpegQuality),
              let baseData = baseImage.jpegData(compressionQuality: jpegQuality),
              let strokesData = try? JSONEncoder().encode(session) else { return false }

        let artwork = items[index]
        let previewURL = imageURL(for: artwork)
        let baseURL = baseImageURL(for: artwork)
        let strokesURL = strokesURL(for: artwork)

        do {
            try previewData.write(to: previewURL, options: .atomic)
            try baseData.write(to: baseURL, options: .atomic)
            try strokesData.write(to: strokesURL, options: .atomic)
            ImageCache.shared.removeLocalCache(for: previewURL)
            ImageCache.shared.removeLocalCache(for: baseURL)
            return true
        } catch {
            return false
        }
    }

    func delete(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let artwork = items[index]
        let previewURL = imageURL(for: artwork)
        let baseURL = baseImageURL(for: artwork)
        let strokesURL = strokesURL(for: artwork)
        try? FileManager.default.removeItem(at: previewURL)
        try? FileManager.default.removeItem(at: baseURL)
        try? FileManager.default.removeItem(at: strokesURL)
        ImageCache.shared.removeLocalCache(for: previewURL)
        ImageCache.shared.removeLocalCache(for: baseURL)
        items.remove(at: index)
        persist()
    }

    var published: [SavedArtwork] {
        items.filter { !$0.isDraft }
    }

    var drafts: [SavedArtwork] {
        items.filter(\.isDraft)
    }

    var favorites: [SavedArtwork] {
        items
            .filter(\.isFavorite)
            .sorted { ($0.favoritedAt ?? $0.createdAt) > ($1.favoritedAt ?? $1.createdAt) }
    }

    private func baseFilename(for id: UUID) -> String {
        "\(id.uuidString)-base.jpg"
    }

    private func strokesFilename(for id: UUID) -> String {
        "\(id.uuidString)-strokes.json"
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let decoded = try? JSONDecoder().decode([SavedArtwork].self, from: data) else { return }
        var needsPersist = false
        items = decoded
            .filter { FileManager.default.fileExists(atPath: imageURL(for: $0).path) }
            .map { artwork in
                var migrated = artwork
                if migrated.isFavorite, migrated.favoritedAt == nil {
                    migrated.favoritedAt = migrated.createdAt
                    needsPersist = true
                }
                return migrated
            }
        if needsPersist { persist() }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: metadataKey)
    }
}

struct SharedArtworkImage: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .image) { item in
            SentTransferredFile(item.url)
        } importing: { received in
            SharedArtworkImage(url: received.file)
        }
    }
}

struct AppNotification: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var message: String
    var createdAt: Date
    var isRead: Bool
}

enum MSToastStyle: Equatable {
    case success
    case error
    case info
}

@Observable
final class AppStore {
    var artworkStore = ArtworkStore()
    var toastMessage: String?
    var toastStyle: MSToastStyle = .success
    var pendingMedium: CanvasMediumSelection?
    var canvasFullscreen = false
    var studioDetailActive = false
    var pendingCanvasBackground: UIImage?
    var editingArtworkID: UUID?
    var notifications: [AppNotification] = []
    var appLanguage: AppLanguage
    var appAppearance: AppAppearance
    var deviceId: String = ""
    var customDisplayName: String = ""
    var customBio: String = ""
    var profileAvatarFilename: String?

    private let notificationsKey = "artbloom.notifications"
    private let communityFavoritesKey = "artbloom.community_favorites"
    private let mediumFavoritesKey = "artbloom.medium_favorites"
    private let hapticsKey = "artbloom.haptics_enabled"
    private let profileKey = "artbloom.user_profile"
    private let profileAvatarName = "avatar.jpg"
    private(set) var favoriteCommunityURLs: Set<String> = []
    private(set) var favoriteMediumURLs: Set<String> = []
    var hapticsEnabled = true

    var resolvedLocale: Locale {
        appLanguage.locale ?? Locale.current
    }

    var preferredColorScheme: ColorScheme? {
        appAppearance.colorScheme
    }

    var profileDisplayName: String {
        let trimmed = customDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.myStudio : trimmed
    }

    var profileBio: String {
        let trimmed = customBio.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.aspiringVisionary : trimmed
    }

    var profileAvatarFileURL: URL? {
        guard let profileAvatarFilename else { return nil }
        let url = profileDirectory.appendingPathComponent(profileAvatarFilename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private var profileDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Profile", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    var isDarkModeEnabled: Bool {
        appAppearance == .dark
    }

    init() {
        appLanguage = AppLanguage.load()
        appAppearance = AppAppearance.load()
        L10n.apply(locale: resolvedLocale, languageCode: appLanguage.bundleLanguageCode)
        loadNotifications()
        loadCommunityFavorites()
        loadMediumFavorites()
        loadHapticsPreference()
        loadProfile()
    }

    func setHapticsEnabled(_ enabled: Bool) {
        guard hapticsEnabled != enabled else { return }
        hapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: hapticsKey)
        CanvasHaptics.isEnabled = enabled
        if enabled { CanvasHaptics.light() }
    }

    func clearInspirationFavorites() {
        guard !favoriteCommunityURLs.isEmpty || !favoriteMediumURLs.isEmpty else { return }
        favoriteCommunityURLs.removeAll()
        favoriteMediumURLs.removeAll()
        persistCommunityFavorites()
        persistMediumFavorites()
        showToast(L10n.inspirationFavoritesCleared, style: .info)
    }

    func clearImageCaches() {
        ImageCache.shared.clearRemoteImageCaches()
        showToast(L10n.cacheCleared, style: .info)
    }

    func loadDeviceIdIfNeeded() async {
        guard deviceId.isEmpty else { return }
        deviceId = await ArtBloomDeviceManager.shared.getDeviceId()
    }

    func copyDeviceIdToClipboard() {
        guard !deviceId.isEmpty else { return }
        UIPasteboard.general.string = deviceId
        showToast(L10n.userIdCopied, style: .info)
        CanvasHaptics.light()
    }

    @discardableResult
    func updateDisplayName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        customDisplayName = trimmed
        persistProfile()
        CanvasHaptics.light()
        return true
    }

    @discardableResult
    func updateBio(_ bio: String) -> Bool {
        let trimmed = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        customBio = trimmed
        persistProfile()
        CanvasHaptics.light()
        return true
    }

    @discardableResult
    func updateAvatar(from image: UIImage) -> Bool {
        let url = profileDirectory.appendingPathComponent(profileAvatarName)
        let resized = ImageDownsampler.resize(image, to: CGSize(width: 512, height: 512), scale: 1)
        guard let data = resized.jpegData(compressionQuality: 0.88) else { return false }

        do {
            try data.write(to: url, options: .atomic)
            profileAvatarFilename = profileAvatarName
            persistProfile()
            ImageCache.shared.removeLocalCache(for: url)
            CanvasHaptics.light()
            return true
        } catch {
            return false
        }
    }

    var hasInspirationFavorites: Bool {
        !favoriteCommunityURLs.isEmpty || !favoriteMediumURLs.isEmpty
    }

    func setLanguage(_ language: AppLanguage) {
        guard appLanguage != language else { return }
        appLanguage = language
        language.persist()
        L10n.apply(locale: resolvedLocale, languageCode: appLanguage.bundleLanguageCode)
        refreshSystemNotificationLocalization()
        if let pendingMedium {
            self.pendingMedium = CanvasMediumSelection(
                name: pendingMedium.localizedName,
                kind: pendingMedium.kind,
                imageURL: pendingMedium.imageURL
            )
        }
        showToast(L10n.languageChanged, style: .info)
    }

    func setDarkModeEnabled(_ enabled: Bool) {
        setAppearance(enabled ? .dark : .system)
    }

    func setAppearance(_ appearance: AppAppearance) {
        guard appAppearance != appearance else { return }
        appAppearance = appearance
        appearance.persist()
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func markAllNotificationsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        persistNotifications()
    }

    func markNotificationRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
        persistNotifications()
    }

    func beginEditingArtwork(_ id: UUID) {
        editingArtworkID = id
        pendingCanvasBackground = nil
    }

    func clearEditingSession() {
        editingArtworkID = nil
    }

    func applyMedium(_ selection: CanvasMediumSelection) {
        pendingMedium = selection
    }

    func applyInspiration(_ selection: CanvasMediumSelection, loadReferenceImage: Bool = true) {
        applyMedium(selection)
        guard loadReferenceImage, let urlString = selection.imageURL, !urlString.isEmpty else { return }
        Task {
            let image = await ImageCache.shared.loadImage(
                urlString: urlString,
                targetSize: CGSize(width: 1200, height: 1200)
            )
            await MainActor.run {
                if let image {
                    self.pendingCanvasBackground = image
                }
            }
        }
    }

    func showToast(_ message: String, style: MSToastStyle = .success) {
        toastStyle = style
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toastMessage == message {
                self?.toastMessage = nil
            }
        }
    }

    @discardableResult
    func toggleFavoriteArtwork(_ id: UUID) -> Bool? {
        guard let artwork = artworkStore.artwork(with: id) else { return nil }
        let wasFavorite = artwork.isFavorite
        artworkStore.toggleFavorite(id)
        showToast(wasFavorite ? L10n.favoriteRemoved : L10n.favoriteAdded)
        CanvasHaptics.light()
        return !wasFavorite
    }

    func isCommunityFavorite(_ imageURL: String) -> Bool {
        favoriteCommunityURLs.contains(imageURL)
    }

    @discardableResult
    func toggleCommunityFavorite(_ imageURL: String) -> Bool {
        let wasFavorite = favoriteCommunityURLs.contains(imageURL)
        if wasFavorite {
            favoriteCommunityURLs.remove(imageURL)
            showToast(L10n.favoriteRemoved)
        } else {
            favoriteCommunityURLs.insert(imageURL)
            showToast(L10n.favoriteAdded)
        }
        persistCommunityFavorites()
        CanvasHaptics.light()
        return !wasFavorite
    }

    func isMediumFavorite(_ imageURL: String) -> Bool {
        favoriteMediumURLs.contains(imageURL)
    }

    @discardableResult
    func toggleMediumFavorite(_ imageURL: String) -> Bool {
        let wasFavorite = favoriteMediumURLs.contains(imageURL)
        if wasFavorite {
            favoriteMediumURLs.remove(imageURL)
            showToast(L10n.favoriteRemoved)
        } else {
            favoriteMediumURLs.insert(imageURL)
            showToast(L10n.favoriteAdded)
        }
        persistMediumFavorites()
        CanvasHaptics.light()
        return !wasFavorite
    }

    var favoriteMediumItems: [MediumItem] {
        SampleData.mediums.filter { favoriteMediumURLs.contains($0.imageURL) }
    }

    var favoriteCommunityItems: [CommunityArt] {
        SampleData.communityArts.filter { favoriteCommunityURLs.contains($0.imageURL) }
    }

    var totalFavoriteCount: Int {
        artworkStore.favorites.count + favoriteMediumURLs.count + favoriteCommunityURLs.count
    }

    private func loadCommunityFavorites() {
        if let urls = UserDefaults.standard.stringArray(forKey: communityFavoritesKey) {
            favoriteCommunityURLs = Set(urls)
        }
    }

    private func persistCommunityFavorites() {
        UserDefaults.standard.set(Array(favoriteCommunityURLs), forKey: communityFavoritesKey)
    }

    private func loadMediumFavorites() {
        if let urls = UserDefaults.standard.stringArray(forKey: mediumFavoritesKey) {
            favoriteMediumURLs = Set(urls)
        }
    }

    private func persistMediumFavorites() {
        UserDefaults.standard.set(Array(favoriteMediumURLs), forKey: mediumFavoritesKey)
    }

    private func loadHapticsPreference() {
        if UserDefaults.standard.object(forKey: hapticsKey) != nil {
            hapticsEnabled = UserDefaults.standard.bool(forKey: hapticsKey)
        }
        CanvasHaptics.isEnabled = hapticsEnabled
    }

    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data),
           !decoded.isEmpty {
            notifications = decoded
            refreshSystemNotificationLocalization()
            return
        }
        notifications = SampleData.initialNotifications
        persistNotifications()
    }

    private func refreshSystemNotificationLocalization() {
        let localizedByID = Dictionary(
            uniqueKeysWithValues: SampleData.initialNotifications.map { ($0.id, ($0.title, $0.message)) }
        )
        var didChange = false
        for index in notifications.indices {
            guard let localized = localizedByID[notifications[index].id] else { continue }
            if notifications[index].title != localized.0 || notifications[index].message != localized.1 {
                notifications[index].title = localized.0
                notifications[index].message = localized.1
                didChange = true
            }
        }
        if didChange {
            persistNotifications()
        }
    }

    private func persistNotifications() {
        guard let data = try? JSONEncoder().encode(notifications) else { return }
        UserDefaults.standard.set(data, forKey: notificationsKey)
    }

    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(StoredUserProfile.self, from: data) else { return }
        customDisplayName = profile.displayName
        customBio = profile.bio
        profileAvatarFilename = profile.avatarFilename
    }

    private func persistProfile() {
        let profile = StoredUserProfile(
            displayName: customDisplayName,
            avatarFilename: profileAvatarFilename,
            bio: customBio
        )
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }
}
