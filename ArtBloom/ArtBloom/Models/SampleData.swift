import Foundation

struct InspirationItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageURL: String
}

struct MediumItem: Identifiable {
    let id = UUID()
    let name: String
    let kind: MediumKind
    let imageURL: String
}

struct CommunityArt: Identifiable {
    let id = UUID()
    let author: String
    let imageURL: String
    var aspectRatio: CGFloat = 1.0
}

struct StyleTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let imageURL: String
    let kind: MediumKind
}

struct ArtworkItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageURL: String
    let mediumKind: MediumKind
    var isFeatured: Bool = false
    var columnSpan: Int = 1
    var rowSpan: Int = 1
}

enum SampleData {
    /// Unsplash 欧美性感时尚人像，国内网络可访问
    private static func image(_ photoID: String, width: Int = 800) -> String {
        "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=\(width)&q=80"
    }

    /// 竖版人像裁切，优先保留面部区域
    private static func portraitImage(_ photoID: String, width: Int = 500, aspectRatio: CGFloat = 4 / 5) -> String {
        let height = max(1, Int((CGFloat(width) / aspectRatio).rounded()))
        return "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&crop=faces&w=\(width)&h=\(height)&q=80"
    }

    private enum Portrait {
        static let editorial = "photo-1534528741775-53994a69daeb"
        static let fashion = "photo-1529139574466-a303027c1d8b"
        static let goldenHour = "photo-1488426862026-3ee34a7d66df"
        static let studio = "photo-1524504388940-b1c1722653e1"
        static let classic = "photo-1554151228-14d9def656e4"
        static let natural = "photo-1544005313-94ddf0286df2"
        static let street = "photo-1529626455594-4ff0802cfb7e"
        static let softLight = "photo-1517841905240-472988babdf9"
        static let candid = "photo-1531746020798-e6953c6e8e04"
        static let professional = "photo-1494790108377-be9c29b29330"
        static let elegant = "photo-1508214751196-bcfd4ca60f91"
    }

    static var heroInspiration: InspirationItem {
        InspirationItem(
            title: L10n.heroTitle,
            subtitle: L10n.dailyInspiration,
            imageURL: image(Portrait.fashion, width: 900)
        )
    }

    static let avatarURL = image(Portrait.editorial, width: 200)

    static var mediums: [MediumItem] {
        [
            MediumItem(name: L10n.mediumOilPainting, kind: .oilPainting, imageURL: image(Portrait.professional, width: 400)),
            MediumItem(name: L10n.mediumWatercolor, kind: .watercolor, imageURL: image(Portrait.goldenHour, width: 400)),
            MediumItem(name: L10n.mediumSketch, kind: .sketch, imageURL: image(Portrait.editorial, width: 400)),
            MediumItem(name: L10n.mediumDigitalArt, kind: .digitalArt, imageURL: image(Portrait.studio, width: 400))
        ]
    }

    static func previewImageURL(for kind: MediumKind) -> String {
        if let match = mediums.first(where: { $0.kind == kind }) {
            return match.imageURL
        }
        if let match = styleTemplates().first(where: { $0.kind == kind }) {
            return match.imageURL
        }
        if let match = profileArtworks.first(where: { $0.mediumKind == kind }) {
            return match.imageURL
        }
        return heroInspiration.imageURL
    }

    static let communityArts: [CommunityArt] = [
        CommunityArt(author: "@clara_creations", imageURL: image(Portrait.street, width: 600), aspectRatio: 0.75),
        CommunityArt(author: "@arch_minimal", imageURL: image(Portrait.classic, width: 600), aspectRatio: 1.2),
        CommunityArt(author: "@nature_luxe", imageURL: image(Portrait.softLight, width: 600), aspectRatio: 0.9),
        CommunityArt(author: "@gold_resin_art", imageURL: image(Portrait.elegant, width: 600), aspectRatio: 1.1),
        CommunityArt(author: "@the_pencil_case", imageURL: image(Portrait.candid, width: 600), aspectRatio: 0.85),
        CommunityArt(author: "@neo_sculpt", imageURL: image(Portrait.natural, width: 600), aspectRatio: 1.0)
    ]

    static let templateStreetStyleAsset = "asset://TemplateUrbanStreet"

    static func styleTemplates() -> [StyleTemplate] {
        [
            StyleTemplate(name: L10n.templateVintageBloom, description: L10n.templateVintageBloomDesc, imageURL: portraitImage(Portrait.classic, width: 500), kind: .vintageBloom),
            StyleTemplate(name: L10n.templateModernChic, description: L10n.templateModernChicDesc, imageURL: portraitImage(Portrait.fashion, width: 500), kind: .modernChic),
            StyleTemplate(name: L10n.templateDreamyPastel, description: L10n.templateDreamyPastelDesc, imageURL: portraitImage(Portrait.studio, width: 500), kind: .dreamyPastel),
            StyleTemplate(name: L10n.templateStreetStyle, description: L10n.templateStreetStyleDesc, imageURL: templateStreetStyleAsset, kind: .streetStyle)
        ]
    }

    static var profileArtworks: [ArtworkItem] {
        [
            ArtworkItem(title: L10n.artworkEtherealHorizons, subtitle: L10n.artworkEtherealHorizonsSub, imageURL: image(Portrait.fashion, width: 900), mediumKind: .watercolor, isFeatured: true, columnSpan: 2, rowSpan: 2),
            ArtworkItem(title: L10n.artworkGalleryStudy, subtitle: L10n.artworkArchitecture, imageURL: image(Portrait.classic, width: 500), mediumKind: .sketch),
            ArtworkItem(title: L10n.artworkFloatingPetals, subtitle: L10n.artworkDigitalPainting, imageURL: image(Portrait.softLight, width: 500), mediumKind: .dreamyPastel),
            ArtworkItem(title: L10n.artworkGlassDroplets, subtitle: L10n.artworkMacro, imageURL: image(Portrait.studio, width: 500), mediumKind: .digitalArt),
            ArtworkItem(title: L10n.artworkBioluminescent, subtitle: L10n.artworkPortrait, imageURL: image(Portrait.editorial, width: 500), mediumKind: .modernChic),
            ArtworkItem(title: L10n.artworkDawnReverie, subtitle: L10n.artworkPanoramicDraft, imageURL: image(Portrait.elegant, width: 900), mediumKind: .inspiration, columnSpan: 2)
        ]
    }

    static let profileAvatarURL = image(Portrait.editorial, width: 300)

    static var initialNotifications: [AppNotification] {
        [
            AppNotification(
                id: UUID(uuidString: "A1000001-0000-0000-0000-000000000001")!,
                title: L10n.notificationWelcomeTitle,
                message: L10n.notificationWelcomeBody,
                createdAt: Date().addingTimeInterval(-86400),
                isRead: true
            ),
            AppNotification(
                id: UUID(uuidString: "A1000001-0000-0000-0000-000000000002")!,
                title: L10n.notificationTransformTitle,
                message: L10n.notificationTransformBody,
                createdAt: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            AppNotification(
                id: UUID(uuidString: "A1000001-0000-0000-0000-000000000003")!,
                title: L10n.notificationCommunityTitle,
                message: L10n.notificationCommunityBody,
                createdAt: Date().addingTimeInterval(-900),
                isRead: false
            )
        ]
    }
}
