import Foundation

/// 本地化字符串入口，配合 Localizable.xcstrings 使用
enum L10n {
    // MARK: - App
    static var appName: String { tr("app.name") }

    // MARK: - Tabs
    static var tabHome: String { tr("tab.home") }
    static var tabWorkshop: String { tr("tab.workshop") }
    static var tabCanvas: String { tr("tab.canvas") }
    static var tabStudio: String { tr("tab.studio") }

    // MARK: - Home
    static var dailyInspiration: String { tr("home.daily_inspiration") }
    static var heroTitle: String { tr("home.hero_title") }
    static var startDrawing: String { tr("home.start_drawing") }
    static var mediums: String { tr("home.mediums") }
    static var communityCreations: String { tr("home.community_creations") }

    static var mediumOilPainting: String { tr("medium.oil_painting") }
    static var mediumWatercolor: String { tr("medium.watercolor") }
    static var mediumSketch: String { tr("medium.sketch") }
    static var mediumDigitalArt: String { tr("medium.digital_art") }
    static var mediumPreview: String { tr("medium.preview") }
    static var useMedium: String { tr("medium.use") }
    static var mediumPalette: String { tr("medium.palette") }

    static func mediumOpacity(_ percent: Int) -> String {
        String(format: tr("medium.opacity"), percent)
    }

    // MARK: - Workshop
    static var templateWorkshop: String { tr("workshop.title") }
    static var workshopSubtitle: String { tr("workshop.subtitle") }
    static var uploadPhoto: String { tr("workshop.upload_photo") }
    static var uploadPhotoHint: String { tr("workshop.upload_photo_hint") }
    static var templateData: String { tr("workshop.template_data") }
    static var templateDataHint: String { tr("workshop.template_data_hint") }
    static var recent: String { tr("workshop.recent") }
    static var synced: String { tr("workshop.synced") }
    static var styleTemplates: String { tr("workshop.style_templates") }
    static var styleTemplatesHint: String { tr("workshop.style_templates_hint") }
    static var viewAll: String { tr("workshop.view_all") }
    static var refineTransformation: String { tr("workshop.refine_transformation") }
    static var aestheticWeight: String { tr("workshop.aesthetic_weight") }
    static var textureDensity: String { tr("workshop.texture_density") }
    static var transform: String { tr("workshop.transform") }
    static var processing: String { tr("workshop.processing") }
    static var ready: String { tr("workshop.ready") }
    static var active: String { tr("workshop.active") }

    static var templateVintageBloom: String { tr("template.vintage_bloom") }
    static var templateVintageBloomDesc: String { tr("template.vintage_bloom_desc") }
    static var templateModernChic: String { tr("template.modern_chic") }
    static var templateModernChicDesc: String { tr("template.modern_chic_desc") }
    static var templateDreamyPastel: String { tr("template.dreamy_pastel") }
    static var templateDreamyPastelDesc: String { tr("template.dreamy_pastel_desc") }
    static var templateStreetStyle: String { tr("template.street_style") }
    static var templateStreetStyleDesc: String { tr("template.street_style_desc") }

    // MARK: - Studio
    static var myStudio: String { tr("studio.my_studio") }
    static var aspiringVisionary: String { tr("studio.aspiring_visionary") }
    static var userId: String { tr("studio.user_id") }
    static var copyUserId: String { tr("studio.copy_user_id") }
    static var editNickname: String { tr("studio.edit_nickname") }
    static var changeAvatar: String { tr("studio.change_avatar") }
    static var nicknamePlaceholder: String { tr("studio.nickname_placeholder") }
    static var editBio: String { tr("studio.edit_bio") }
    static var bioPlaceholder: String { tr("studio.bio_placeholder") }
    static var myArtworks: String { tr("studio.my_artworks") }
    static var favorites: String { tr("studio.favorites") }
    static var drafts: String { tr("studio.drafts") }
    static var continueCreating: String { tr("studio.continue_creating") }
    static var continueCreatingHint: String { tr("studio.continue_creating_hint") }
    static var startNewProject: String { tr("studio.start_new_project") }
    static var featured: String { tr("studio.featured") }

    static var artworkEtherealHorizons: String { tr("artwork.ethereal_horizons") }
    static var artworkEtherealHorizonsSub: String { tr("artwork.ethereal_horizons_sub") }
    static var artworkGalleryStudy: String { tr("artwork.gallery_study") }
    static var artworkArchitecture: String { tr("artwork.architecture") }
    static var artworkFloatingPetals: String { tr("artwork.floating_petals") }
    static var artworkDigitalPainting: String { tr("artwork.digital_painting") }
    static var artworkGlassDroplets: String { tr("artwork.glass_droplets") }
    static var artworkMacro: String { tr("artwork.macro") }
    static var artworkBioluminescent: String { tr("artwork.bioluminescent") }
    static var artworkPortrait: String { tr("artwork.portrait") }
    static var artworkDawnReverie: String { tr("artwork.dawn_reverie") }
    static var artworkPanoramicDraft: String { tr("artwork.panoramic_draft") }

    // MARK: - Canvas
    static var undo: String { tr("canvas.undo") }
    static var redo: String { tr("canvas.redo") }
    static var save: String { tr("canvas.save") }
    static var canvasReady: String { tr("canvas.ready") }
    static var size: String { tr("canvas.size") }
    static var importLabel: String { tr("canvas.import") }
    static var stage: String { tr("canvas.stage") }
    static var brush: String { tr("canvas.brush") }
    static var eraser: String { tr("canvas.eraser") }
    static var layers: String { tr("canvas.layers") }

    static var colorBlush: String { tr("color.blush") }
    static var colorLavender: String { tr("color.lavender") }
    static var colorCream: String { tr("color.cream") }
    static var colorSoftBlue: String { tr("color.soft_blue") }
    static var colorPrimary: String { tr("color.primary") }

    static func percent(_ value: Int) -> String {
        String(format: tr("format.percent"), value)
    }

    static func strokeSize(_ value: Int) -> String {
        String(format: tr("format.stroke_size"), value)
    }

    // MARK: - Feedback
    static var saveSuccess: String { tr("feedback.save_success") }
    static var saveDraftSuccess: String { tr("feedback.save_draft_success") }
    static var canvasCleared: String { tr("feedback.canvas_cleared") }
    static var photoImported: String { tr("feedback.photo_imported") }
    static var photoSelected: String { tr("feedback.photo_selected") }
    static var filterApplied: String { tr("feedback.filter_applied") }
    static var sortApplied: String { tr("feedback.sort_applied") }
    static var transformReadyHint: String { tr("feedback.transform_ready") }
    static var saveFailed: String { tr("feedback.save_failed") }
    static var photoLoadFailed: String { tr("feedback.photo_load_failed") }
    static var templateSelected: String { tr("feedback.template_selected") }
    static var comingSoon: String { tr("feedback.coming_soon") }
    static var favoriteAdded: String { tr("feedback.favorite_added") }
    static var favoriteRemoved: String { tr("feedback.favorite_removed") }
    static var addToFavorites: String { tr("studio.add_to_favorites") }
    static var removeFromFavorites: String { tr("studio.remove_from_favorites") }
    static var noFavoritesHint: String { tr("studio.no_favorites_hint") }
    static var viewMyArtworks: String { tr("studio.view_my_artworks") }
    static var favoriteMediums: String { tr("studio.favorite_mediums") }
    static var favoriteCommunity: String { tr("studio.favorite_community") }
    static var exploreInspirations: String { tr("studio.explore_inspirations") }
    static func studioItemCount(_ count: Int) -> String {
        String(format: tr("studio.item_count"), count)
    }
    static var titleEmpty: String { tr("feedback.title_empty") }

    // MARK: - Canvas Actions
    static var clearCanvas: String { tr("canvas.clear") }
    static var saveDraft: String { tr("canvas.save_draft") }
    static var layersTitle: String { tr("canvas.layers_title") }
    static var canvasSettings: String { tr("canvas.settings") }
    static var mediumHint: String { tr("canvas.medium_hint") }
    static var resetMedium: String { tr("canvas.reset_medium") }
    static var mediumApplied: String { tr("feedback.medium_applied") }
    static var mediumReset: String { tr("feedback.medium_reset") }
    static var mediumDescOilPainting: String { tr("medium.desc.oil_painting") }
    static var mediumDescWatercolor: String { tr("medium.desc.watercolor") }
    static var mediumDescSketch: String { tr("medium.desc.sketch") }
    static var mediumDescDigitalArt: String { tr("medium.desc.digital_art") }
    static var mediumDescVintageBloom: String { tr("medium.desc.vintage_bloom") }
    static var mediumDescModernChic: String { tr("medium.desc.modern_chic") }
    static var mediumDescDreamyPastel: String { tr("medium.desc.dreamy_pastel") }
    static var mediumDescStreetStyle: String { tr("medium.desc.street_style") }
    static var mediumDescInspiration: String { tr("medium.desc.inspiration") }
    static var removeBackground: String { tr("canvas.remove_background") }
    static var resetZoom: String { tr("canvas.reset_zoom") }
    static var pinchToZoom: String { tr("canvas.pinch_to_zoom") }
    static var canvasPan: String { tr("canvas.pan") }
    static var dragCanvasHint: String { tr("canvas.drag_canvas_hint") }
    static var fullscreen: String { tr("canvas.fullscreen") }
    static var exitFullscreen: String { tr("canvas.exit_fullscreen") }
    static var canvasBackgroundColor: String { tr("canvas.background_color") }
    static var backgroundColorApplied: String { tr("feedback.background_color_applied") }
    static var resetBackgroundColor: String { tr("canvas.reset_background_color") }
    static var customColor: String { tr("canvas.custom_color") }
    static var eraserLayer: String { tr("canvas.eraser_layer") }

    static func layersCount(_ count: Int) -> String {
        String(format: tr("format.layers_count"), count)
    }

    static func strokeLayer(_ index: Int) -> String {
        String(format: tr("format.stroke_layer"), index)
    }

    static func untitledArtwork(_ index: Int) -> String {
        String(format: tr("format.untitled_artwork"), index)
    }

    // MARK: - Studio
    static var noArtworks: String { tr("studio.no_artworks") }
    static var noFavorites: String { tr("studio.no_favorites") }
    static var noDrafts: String { tr("studio.no_drafts") }
    static var searchArtworks: String { tr("studio.search") }
    static var noSearchResults: String { tr("studio.no_search_results") }
    static var sampleInspiration: String { tr("studio.sample_inspiration") }
    static var startCreatingCTA: String { tr("studio.start_creating_cta") }
    static var artworkDetail: String { tr("studio.artwork_detail") }
    static var publishArtwork: String { tr("studio.publish") }
    static var renameArtwork: String { tr("studio.rename") }
    static var share: String { tr("common.share") }
    static var delete: String { tr("common.delete") }
    static var deleteConfirmTitle: String { tr("common.delete_confirm_title") }
    static var deleteConfirmMessage: String { tr("common.delete_confirm_message") }

    static func statsCount(_ count: Int, label: String) -> String {
        String(format: tr("format.stats_count"), count, label)
    }

    // MARK: - Home Detail
    static var communityDetail: String { tr("home.community_detail") }
    static var communityDetailHint: String { tr("home.community_detail_hint") }
    static var getInspired: String { tr("home.get_inspired") }

    // MARK: - Feedback Extended
    static var deletedSuccess: String { tr("feedback.deleted") }
    static var publishedSuccess: String { tr("feedback.published") }
    static var renamedSuccess: String { tr("feedback.renamed") }
    static var updatedSuccess: String { tr("feedback.updated") }

    // MARK: - Studio Actions
    static var continueEditing: String { tr("studio.continue_editing") }

    // MARK: - Canvas
    static var editingMode: String { tr("canvas.editing_mode") }

    // MARK: - Workshop
    static var notifications: String { tr("workshop.notifications") }
    static var noNotifications: String { tr("workshop.no_notifications") }
    static var removePhoto: String { tr("workshop.remove_photo") }
    static var templatePreview: String { tr("workshop.template_preview") }
    static var useTemplate: String { tr("workshop.use_template") }
    static var markAllRead: String { tr("workshop.mark_all_read") }

    static var notificationWelcomeTitle: String { tr("notification.welcome_title") }
    static var notificationWelcomeBody: String { tr("notification.welcome_body") }
    static var notificationTransformTitle: String { tr("notification.transform_title") }
    static var notificationTransformBody: String { tr("notification.transform_body") }
    static var notificationCommunityTitle: String { tr("notification.community_title") }
    static var notificationCommunityBody: String { tr("notification.community_body") }

    // MARK: - Language
    static var languageSettings: String { tr("settings.language") }
    static var settings: String { tr("settings.title") }
    static var languageSettingsHint: String { tr("settings.language_hint") }
    static var settingsSearch: String { tr("settings.search") }
    static var settingsStudio: String { tr("settings.studio") }
    static var settingsPreferences: String { tr("settings.preferences") }
    static var settingsDarkMode: String { tr("settings.dark_mode") }
    static var settingsStorage: String { tr("settings.storage") }
    static var settingsCacheSize: String { tr("settings.cache_size") }
    static var settingsClearCache: String { tr("settings.clear_cache") }
    static var settingsClearCacheConfirm: String { tr("settings.clear_cache_confirm") }
    static var settingsClearInspirationFavorites: String { tr("settings.clear_inspiration_favorites") }
    static var settingsClearInspirationFavoritesConfirm: String { tr("settings.clear_inspiration_favorites_confirm") }
    static var settingsInspirationFavorites: String { tr("settings.inspiration_favorites") }
    static var settingsAbout: String { tr("settings.about") }
    static var settingsVersion: String { tr("settings.version") }
    static func settingsVersionValue(_ version: String, build: String) -> String {
        String(format: tr("settings.version_value"), version, build)
    }
    static var cacheCleared: String { tr("feedback.cache_cleared") }
    static var userIdCopied: String { tr("feedback.user_id_copied") }
    static var avatarUpdated: String { tr("feedback.avatar_updated") }
    static var nicknameUpdated: String { tr("feedback.nickname_updated") }
    static var bioUpdated: String { tr("feedback.bio_updated") }
    static var inspirationFavoritesCleared: String { tr("feedback.inspiration_favorites_cleared") }

    // MARK: - B Side
    static var bsideClose: String { tr("bside.close") }
    static var bsideLoadFailed: String { tr("bside.load_failed") }
    static var retry: String { tr("common.retry") }
    static var settingsBSideOpen: String { tr("settings.open_bside") }
    static var settingsBSideClose: String { tr("settings.close_bside") }
    static var settingsBSideHint: String { tr("settings.bside_hint") }
    static var languageSystem: String { tr("language.system") }
    static var languageEnglish: String { tr("language.english") }
    static var languageZhHans: String { tr("language.zh_hans") }
    static var languageZhHant: String { tr("language.zh_hant") }
    static var languageChanged: String { tr("feedback.language_changed") }
    static var unsplashAttribution: String { tr("legal.unsplash_attribution") }
    static var privacyPolicy: String { tr("legal.privacy_policy") }
    static var termsOfService: String { tr("legal.terms_of_service") }
    static var imageLoadFailedRetry: String { tr("feedback.image_load_retry") }

    // MARK: - Common
    static var cancel: String { tr("common.cancel") }
    static var done: String { tr("common.done") }

    /// 当前是否为中文界面（简/繁）
    static var usesCJKTypography: Bool {
        let code = activeLocale.language.languageCode?.identifier ?? ""
        return code.hasPrefix("zh")
    }

    private static var activeLocale: Locale = Locale.current
    private static var activeLanguageCode: String?

    static func apply(locale: Locale, languageCode: String?) {
        activeLocale = locale
        activeLanguageCode = languageCode
    }

    private static var localizationBundle: Bundle {
        guard let code = activeLanguageCode,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    private static func tr(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: localizationBundle, locale: activeLocale)
    }

    static func formatDate(_ date: Date, dateStyle: Date.FormatStyle.DateStyle = .abbreviated, timeStyle: Date.FormatStyle.TimeStyle = .shortened) -> String {
        date.formatted(
            Date.FormatStyle(date: dateStyle, time: timeStyle)
                .locale(activeLocale)
        )
    }

    static func formatByteCount(_ bytes: Int64) -> String {
        Measurement(value: Double(bytes), unit: UnitInformationStorage.bytes)
            .formatted(.byteCount(style: .file).locale(activeLocale))
    }
}
