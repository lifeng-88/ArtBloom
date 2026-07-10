import SwiftUI
import PhotosUI

enum StudioCollectionKind: Int, Identifiable {
    case published = 0
    case favorites = 1
    case drafts = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .published: return L10n.myArtworks
        case .favorites: return L10n.favorites
        case .drafts: return L10n.drafts
        }
    }

    var heroIcon: String {
        switch self {
        case .published: return "photo.on.rectangle.angled"
        case .favorites: return "heart.fill"
        case .drafts: return "doc.text"
        }
    }
}

enum StudioCollectionLayout {
    case preview
    case detail
}

struct StudioProfileView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.selectedTab) private var selectedTab

    @State private var selectedTabIndex = 0
    @State private var activeCollection: StudioCollectionKind?
    @State private var selectedArtworkID: UUID?
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var selectedCommunityArt: CommunityArt?
    @State private var previewMedium: MediumItem?
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var showNicknameAlert = false
    @State private var showBioAlert = false
    @State private var nicknameText = ""
    @State private var bioText = ""
    @Namespace private var studioTabNamespace

    private var tabs: [String] { [L10n.myArtworks, L10n.favorites, L10n.drafts] }

    var body: some View {
        NavigationStack {
            studioMainContent
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $activeCollection) { kind in
                    StudioCollectionDetailView(
                        kind: kind,
                        selectedArtworkID: $selectedArtworkID,
                        selectedCommunityArt: $selectedCommunityArt,
                        previewMedium: $previewMedium
                    )
                }
                .onChange(of: activeCollection) { _, collection in
                    appStore.studioDetailActive = collection != nil
                }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet()
        }
        .sheet(isPresented: $showSettings) {
            StudioSettingsView()
        }
        .sheet(isPresented: Binding(
            get: { selectedArtworkID != nil },
            set: { if !$0 { selectedArtworkID = nil } }
        )) {
            if let selectedArtworkID {
                ArtworkDetailView(artworkID: selectedArtworkID)
            }
        }
        .sheet(item: $selectedCommunityArt) { art in
            CommunityDetailView(art: art)
        }
        .sheet(item: $previewMedium) { medium in
            MediumPreviewSheet(medium: medium) {
                appStore.clearEditingSession()
                appStore.applyInspiration(CanvasMediumSelection(name: medium.name, kind: medium.kind, imageURL: medium.imageURL))
                previewMedium = nil
                selectedTab?.wrappedValue = .canvas
            }
        }
    }

    private var studioMainContent: some View {
        ZStack(alignment: .top) {
            MSBrandBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: MSLayout.topBarHeight + 16)

                    profileHeader
                        .padding(.bottom, 40)

                    tabSelector
                        .padding(.horizontal, MSSpacing.containerPadding)
                        .padding(.bottom, 32)

                    StudioCollectionContent(
                        kind: currentCollectionKind,
                        layout: .preview,
                        selectedArtworkID: $selectedArtworkID,
                        selectedCommunityArt: $selectedCommunityArt,
                        previewMedium: $previewMedium
                    )
                    .padding(.horizontal, MSSpacing.containerPadding)

                    if shouldShowContinueCreating {
                        continueCreating
                            .padding(.horizontal, MSSpacing.containerPadding)
                            .padding(.top, 16)
                    }
                }
                .msScrollContentWidth()
                .padding(.bottom, MSLayout.tabContentBottomInset)
            }
            .msPageScroll()

            GlassTopBar(title: L10n.appName, icon: "paintpalette.fill") {
                HStack(spacing: 16) {
                    Button { showNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .foregroundStyle(MSColor.onSurfaceVariant)
                            if appStore.unreadNotificationCount > 0 {
                                Circle()
                                    .fill(MSColor.primary)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel(L10n.notifications)

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(MSColor.onSurfaceVariant)
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel(L10n.settings)
                }
            }
        }
    }

    private var currentCollectionKind: StudioCollectionKind {
        StudioCollectionKind(rawValue: selectedTabIndex) ?? .published
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            avatarPicker

            VStack(spacing: 4) {
                nicknameButton

                bioButton

                if !appStore.deviceId.isEmpty {
                    userIdBadge
                        .padding(.top, 4)
                }
            }

            studioStats
        }
        .task {
            await appStore.loadDeviceIdIfNeeded()
        }
        .alert(L10n.editNickname, isPresented: $showNicknameAlert) {
            TextField(L10n.nicknamePlaceholder, text: $nicknameText)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.save) {
                if appStore.updateDisplayName(nicknameText) {
                    appStore.showToast(L10n.nicknameUpdated)
                } else {
                    appStore.showToast(L10n.titleEmpty, style: .error)
                }
            }
        }
        .alert(L10n.editBio, isPresented: $showBioAlert) {
            TextField(L10n.bioPlaceholder, text: $bioText)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.save) {
                if appStore.updateBio(bioText) {
                    appStore.showToast(L10n.bioUpdated)
                } else {
                    appStore.showToast(L10n.titleEmpty, style: .error)
                }
            }
        }
        .onChange(of: selectedAvatarItem) { _, item in
            PhotoImportHelper.loadImage(from: item) { image in
                if let image, appStore.updateAvatar(from: image) {
                    appStore.showToast(L10n.avatarUpdated)
                } else if item != nil {
                    appStore.showToast(L10n.photoLoadFailed, style: .error)
                }
                selectedAvatarItem = nil
            }
        }
    }

    private var avatarPicker: some View {
        PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(size: 96, fallbackURL: SampleData.profileAvatarURL)
                    .overlay {
                        Circle()
                            .strokeBorder(MSColor.swatchBorder, lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                Circle()
                    .fill(MSColor.primary)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MSColor.onPrimary)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(MSColor.surface, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(L10n.changeAvatar)
    }

    private var nicknameButton: some View {
        Button {
            nicknameText = appStore.customDisplayName.isEmpty
                ? appStore.profileDisplayName
                : appStore.customDisplayName
            showNicknameAlert = true
        } label: {
            HStack(spacing: 6) {
                MSTypography.headline(appStore.profileDisplayName)
                    .foregroundStyle(MSColor.onSurface)
                Image(systemName: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MSColor.primary.opacity(0.85))
            }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(L10n.editNickname)
    }

    private var bioButton: some View {
        Button {
            bioText = appStore.customBio.isEmpty
                ? appStore.profileBio
                : appStore.customBio
            showBioAlert = true
        } label: {
            HStack(spacing: 6) {
                MSTypography.label(appStore.profileBio)
                    .foregroundStyle(MSColor.onSurfaceVariant)
                Image(systemName: "pencil")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MSColor.primary.opacity(0.75))
            }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(L10n.editBio)
    }

    private var userIdBadge: some View {
        Button {
            appStore.copyDeviceIdToClipboard()
        } label: {
            HStack(spacing: 6) {
                MSTypography.label(L10n.userId)
                    .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.85))
                Text(appStore.deviceId)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Image(systemName: "doc.on.doc")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MSColor.primary.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(MSColor.primaryContainer.opacity(0.4)))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(L10n.copyUserId)
    }

    private var studioStats: some View {
        HStack(spacing: 24) {
            statBadge(
                count: appStore.artworkStore.published.count,
                label: L10n.myArtworks,
                tabIndex: 0
            )
            statBadge(
                count: appStore.totalFavoriteCount,
                label: L10n.favorites,
                tabIndex: 1
            )
            statBadge(
                count: appStore.artworkStore.drafts.count,
                label: L10n.drafts,
                tabIndex: 2
            )
        }
        .padding(.top, 8)
    }

    private func statBadge(count: Int, label: String, tabIndex: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedTabIndex = tabIndex
            }
            if let kind = StudioCollectionKind(rawValue: tabIndex) {
                activeCollection = kind
            }
            CanvasHaptics.light()
        } label: {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(MSColor.primary)
                MSTypography.label(label)
                    .foregroundStyle(MSColor.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressScaleStyle())
    }

    private var shouldShowContinueCreating: Bool {
        appStore.artworkStore.published.isEmpty && selectedTabIndex == 0
    }

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selectedTabIndex = index
                    }
                    CanvasHaptics.light()
                } label: {
                    MSTypography.label(tab)
                        .foregroundStyle(selectedTabIndex == index ? MSColor.onPrimaryContainer : MSColor.onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTabIndex == index {
                                Capsule()
                                    .fill(MSColor.primaryContainer)
                                    .shadow(color: MSShadow.card(.light), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "studioTab", in: studioTabNamespace)
                            }
                        }
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityAddTraits(selectedTabIndex == index ? .isSelected : [])
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(MSColor.surfaceContainerLow.opacity(0.5))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(MSColor.outlineVariant.opacity(0.25), lineWidth: 1))
        }
    }

    private var continueCreating: some View {
        VStack(spacing: 20) {
            MSTypography.headline(L10n.continueCreating)
                .foregroundStyle(MSColor.onSurface)
            MSTypography.body(L10n.continueCreatingHint)
                .foregroundStyle(MSColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Button {
                appStore.clearEditingSession()
                appStore.pendingCanvasBackground = nil
                selectedTab?.wrappedValue = .canvas
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    MSTypography.label(L10n.startNewProject)
                }
                .foregroundStyle(MSColor.onPrimary)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Capsule().fill(MSColor.primary))
                .shadow(color: MSColor.primary.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous)
                .strokeBorder(MSColor.outlineVariant.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .background {
                    RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous)
                        .fill(MSColor.surfaceContainerLow.opacity(0.35))
                }
        }
    }
}

struct StudioCollectionDetailView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.colorScheme) private var colorScheme

    let kind: StudioCollectionKind
    @Binding var selectedArtworkID: UUID?
    @Binding var selectedCommunityArt: CommunityArt?
    @Binding var previewMedium: MediumItem?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: MSSectionSpacing.standard) {
                detailHero

                StudioCollectionContent(
                    kind: kind,
                    layout: .detail,
                    selectedArtworkID: $selectedArtworkID,
                    selectedCommunityArt: $selectedCommunityArt,
                    previewMedium: $previewMedium
                )
            }
            .padding(.horizontal, MSSpacing.containerPadding)
            .padding(.top, 4)
            .padding(.bottom, MSLayout.scrollBottomInset)
            .msScrollContentWidth()
        }
        .msBrandBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MSColor.roseMist.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var detailHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(kind.title)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(MSColor.onSurface)

            HStack(spacing: 8) {
                Image(systemName: kind.heroIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MSColor.primary)
                MSTypography.body(L10n.studioItemCount(itemCount))
                    .foregroundStyle(MSColor.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var itemCount: Int {
        switch kind {
        case .published: return appStore.artworkStore.published.count
        case .favorites: return appStore.totalFavoriteCount
        case .drafts: return appStore.artworkStore.drafts.count
        }
    }
}

struct StudioSectionHeader: View {
    let icon: String
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MSColor.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(MSColor.primaryContainer.opacity(0.5)))

            MSTypography.headline(title)
                .foregroundStyle(MSColor.primary)

            Spacer(minLength: 8)

            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(MSColor.onPrimaryContainer)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(MSColor.primaryContainer.opacity(0.7)))
        }
    }
}

struct StudioCollectionContent: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.selectedTab) private var selectedTab
    @Environment(\.colorScheme) private var colorScheme

    let kind: StudioCollectionKind
    var layout: StudioCollectionLayout = .preview
    @Binding var selectedArtworkID: UUID?
    @Binding var selectedCommunityArt: CommunityArt?
    @Binding var previewMedium: MediumItem?

    var body: some View {
        Group {
            switch kind {
            case .favorites:
                favoritesContent
            case .published, .drafts:
                artworkListContent
            }
        }
    }

    @ViewBuilder
    private var artworkListContent: some View {
        let artworks = artworksForKind

        if artworks.isEmpty {
            if kind == .published {
                inspirationSection
            } else {
                emptyStateWithCTA
            }
        } else {
            savedArtworkGrid(artworks)
        }
    }

    @ViewBuilder
    private var favoritesContent: some View {
        let artworks = appStore.artworkStore.favorites
        let mediums = appStore.favoriteMediumItems
        let community = appStore.favoriteCommunityItems
        let hasResults = !artworks.isEmpty || !mediums.isEmpty || !community.isEmpty
        let showSectionHeaders = [artworks.isEmpty, mediums.isEmpty, community.isEmpty].filter { !$0 }.count > 1

        if !hasResults {
            favoritesEmptyState
        } else {
            VStack(alignment: .leading, spacing: layout == .detail ? 40 : 32) {
                if !artworks.isEmpty {
                    if showSectionHeaders || layout == .detail {
                        StudioSectionHeader(icon: "photo.fill", title: L10n.myArtworks, count: artworks.count)
                    }
                    savedArtworkGrid(artworks)
                }

                if !mediums.isEmpty {
                    if showSectionHeaders || layout == .detail {
                        StudioSectionHeader(icon: "paintpalette.fill", title: L10n.favoriteMediums, count: mediums.count)
                    }
                    favoriteMediumsGrid(mediums)
                }

                if !community.isEmpty {
                    if showSectionHeaders || layout == .detail {
                        StudioSectionHeader(icon: "person.2.fill", title: L10n.favoriteCommunity, count: community.count)
                    }
                    favoriteCommunitySection(community)
                }
            }
        }
    }

    private var artworksForKind: [SavedArtwork] {
        switch kind {
        case .published: return appStore.artworkStore.published
        case .drafts: return appStore.artworkStore.drafts
        case .favorites: return appStore.artworkStore.favorites
        }
    }

    private func favoriteMediumsGrid(_ mediums: [MediumItem]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: MSSpacing.gutter),
                GridItem(.flexible(), spacing: MSSpacing.gutter)
            ],
            spacing: MSSpacing.gutter
        ) {
            ForEach(mediums, id: \.imageURL) { medium in
                FavoriteMediumCard(medium: medium) {
                    previewMedium = medium
                } onUse: {
                    appStore.clearEditingSession()
                    appStore.applyInspiration(
                        CanvasMediumSelection(name: medium.name, kind: medium.kind, imageURL: medium.imageURL)
                    )
                    selectedTab?.wrappedValue = .canvas
                }
            }
        }
    }

    private func favoriteCommunitySection(_ arts: [CommunityArt]) -> some View {
        MasonryGrid(items: arts) { art in
            CommunityArtCard(art: art) {
                selectedCommunityArt = art
            }
        }
    }

    private var favoritesEmptyState: some View {
        MSEmptyState(
            icon: "heart",
            message: L10n.noFavoritesHint,
            actionTitle: L10n.exploreInspirations
        ) {
            selectedTab?.wrappedValue = .home
            CanvasHaptics.light()
        }
    }

    private var emptyStateWithCTA: some View {
        MSEmptyState(
            icon: kind == .drafts ? "doc.text" : "heart",
            message: emptyMessage,
            actionTitle: L10n.startCreatingCTA
        ) {
            appStore.clearEditingSession()
            appStore.pendingCanvasBackground = nil
            selectedTab?.wrappedValue = .canvas
        }
    }

    private var emptyMessage: String {
        switch kind {
        case .drafts: return L10n.noDrafts
        case .published: return L10n.noArtworks
        case .favorites: return L10n.noFavorites
        }
    }

    private func savedArtworkGrid(_ artworks: [SavedArtwork]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: MSSpacing.gutter),
                GridItem(.flexible(), spacing: MSSpacing.gutter)
            ],
            spacing: MSSpacing.gutter
        ) {
            ForEach(artworks) { artwork in
                SavedArtworkCard(artwork: artwork) {
                    toggleFavorite(artwork)
                } onOpen: {
                    selectedArtworkID = artwork.id
                }
                .contextMenu { artworkContextMenu(artwork) }
            }
        }
        .animation(.easeOut(duration: 0.25), value: artworks.map(\.id))
    }

    private func toggleFavorite(_ artwork: SavedArtwork) {
        _ = appStore.toggleFavoriteArtwork(artwork.id)
    }

    @ViewBuilder
    private func artworkContextMenu(_ artwork: SavedArtwork) -> some View {
        Button {
            selectedArtworkID = artwork.id
        } label: {
            Label(L10n.artworkDetail, systemImage: "eye")
        }
        if !artwork.isDraft {
            Button {
                _ = appStore.toggleFavoriteArtwork(artwork.id)
            } label: {
                Label(
                    artwork.isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites,
                    systemImage: artwork.isFavorite ? "heart.slash" : "heart"
                )
            }
        }
        if artwork.isDraft {
            Button {
                appStore.artworkStore.promoteDraft(artwork.id)
                appStore.showToast(L10n.publishedSuccess)
            } label: {
                Label(L10n.publishArtwork, systemImage: "checkmark.seal")
            }
        }
        Button(role: .destructive) {
            appStore.artworkStore.delete(artwork.id)
            appStore.showToast(L10n.deletedSuccess)
        } label: {
            Label(L10n.delete, systemImage: "trash")
        }
    }

    private var inspirationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MSTypography.headline(L10n.sampleInspiration)
                .foregroundStyle(MSColor.primary)
            MSTypography.body(L10n.noArtworks)
                .foregroundStyle(MSColor.onSurfaceVariant)
            bentoGrid
        }
    }

    private var bentoGrid: some View {
        let artworks = SampleData.profileArtworks
        let featured = artworks.first
        let gridItems = Array(artworks.dropFirst().prefix(4))
        let banner = artworks.count > 5 ? artworks[5] : artworks.last

        return VStack(spacing: MSSpacing.gutter) {
            if let featured {
                inspirationCard(featured)
                    .aspectRatio(1, contentMode: .fit)
            }

            if !gridItems.isEmpty {
                HStack(spacing: MSSpacing.gutter) {
                    inspirationCard(gridItems[0])
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    if gridItems.count > 1 {
                        inspirationCard(gridItems[1])
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }

                if gridItems.count > 2 {
                    HStack(spacing: MSSpacing.gutter) {
                        inspirationCard(gridItems[2])
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                        if gridItems.count > 3 {
                            inspirationCard(gridItems[3])
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }

            if let banner, banner.id != featured?.id {
                inspirationCard(banner)
                    .aspectRatio(16 / 9, contentMode: .fit)
            }
        }
    }

    private func inspirationCard(_ artwork: ArtworkItem) -> some View {
        Button {
            appStore.clearEditingSession()
            appStore.applyInspiration(
                CanvasMediumSelection(name: artwork.title, kind: artwork.mediumKind, imageURL: artwork.imageURL)
            )
            selectedTab?.wrappedValue = .canvas
        } label: {
            BentoArtworkCard(artwork: artwork)
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct SavedArtworkCard: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.colorScheme) private var colorScheme
    let artwork: SavedArtwork
    let onFavorite: () -> Void
    let onOpen: () -> Void

    @State private var showRenameAlert = false
    @State private var renameText = ""

    private let cardAspectRatio: CGFloat = 3 / 4

    private var displaySubtitle: String {
        artwork.isDraft ? L10n.formatDate(artwork.createdAt) : artwork.subtitle
    }

    var body: some View {
        Color.clear
            .aspectRatio(cardAspectRatio, contentMode: .fit)
            .overlay {
                LocalArtworkImage(
                    url: appStore.artworkStore.imageURL(for: artwork),
                    targetSize: CGSize(width: 320, height: 426)
                )
                .id(artwork.id)
            }
            .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(artwork.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        if artwork.isDraft {
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    MSTypography.label(displaySubtitle)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    LinearGradient(
                        colors: [.black.opacity(0.65), .black.opacity(0.15), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
            }
            .overlay(alignment: .topTrailing) {
                if artwork.isDraft {
                    Button {
                        renameText = artwork.title
                        showRenameAlert = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.borderless)
                    .padding(8)
                    .accessibilityLabel(L10n.renameArtwork)
                } else {
                    Button(action: onFavorite) {
                        Image(systemName: artwork.isFavorite ? "heart.fill" : "heart")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(artwork.isFavorite ? MSColor.primary : .white)
                            .padding(7)
                            .background(.ultraThinMaterial, in: Circle())
                            .symbolEffect(.bounce, value: artwork.isFavorite)
                    }
                    .buttonStyle(.borderless)
                    .padding(8)
                    .accessibilityLabel(artwork.isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites)
                }
            }
            .overlay(alignment: .topLeading) {
                if artwork.isDraft {
                    MSTypography.label(L10n.drafts)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                        .padding(8)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .onTapGesture(perform: onOpen)
            .msCardShadow(colorScheme, radius: MSShadow.cardRadius)
            .alert(L10n.renameArtwork, isPresented: $showRenameAlert) {
                TextField(L10n.renameArtwork, text: $renameText)
                Button(L10n.save) {
                    if appStore.artworkStore.updateTitle(artwork.id, title: renameText) {
                        appStore.showToast(L10n.renamedSuccess)
                    } else {
                        appStore.showToast(L10n.titleEmpty, style: .error)
                    }
                }
                Button(L10n.cancel, role: .cancel) {}
            }
    }
}

struct FavoriteMediumCard: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.colorScheme) private var colorScheme
    let medium: MediumItem
    let onPreview: () -> Void
    let onUse: () -> Void

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                RemoteImage(
                    url: medium.imageURL,
                    alignment: .top,
                    targetSize: CGSize(width: 320, height: 320)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                FavoriteToggleButton(
                    isFavorite: appStore.isMediumFavorite(medium.imageURL)
                ) {
                    _ = appStore.toggleMediumFavorite(medium.imageURL)
                }
                .padding(8)
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: onPreview) {
                    Image(systemName: "eye.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                }
                .buttonStyle(.borderless)
                .padding(8)
                .accessibilityLabel(L10n.mediumPreview)
            }
            .overlay(alignment: .bottomLeading) {
                MSTypography.label(medium.name)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        LinearGradient(
                            colors: [.black.opacity(0.55), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .onTapGesture(perform: onUse)
            .msCardShadow(colorScheme, radius: MSShadow.cardRadius)
    }
}

struct BentoArtworkCard: View {
    let artwork: ArtworkItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SizedRemoteImage(url: artwork.imageURL, contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            if artwork.isFeatured {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            MSTypography.label(L10n.featured)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                        }
                        .padding(16)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(artwork.title)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    MSTypography.label(artwork.subtitle)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top)
                }
            } else if artwork.columnSpan > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    MSTypography.headline(artwork.title)
                        .foregroundStyle(MSColor.onSurface)
                    MSTypography.label(artwork.subtitle)
                        .foregroundStyle(MSColor.onSurfaceVariant)
                }
                .padding(24)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

#Preview {
    StudioProfileView()
        .environment(AppStore())
}
