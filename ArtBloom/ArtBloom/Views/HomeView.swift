import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.selectedTab) private var selectedTab
    @Environment(\.colorScheme) private var colorScheme

    @State private var communityArts = SampleData.communityArts
    @State private var isSorted = false
    @State private var selectedCommunityArt: CommunityArt?
    @State private var previewMedium: MediumItem?

    var body: some View {
        VStack(spacing: 0) {
            GlassTopBar(title: L10n.appName, icon: "paintpalette.fill") {
                Button {
                    selectedTab?.wrappedValue = .studio
                } label: {
                    ProfileAvatarView()
                }
                .buttonStyle(PressScaleStyle())
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: MSSectionSpacing.loose) {
                    heroSection
                    mediumsSection
                    communitySection
                }
                .padding(.horizontal, MSSpacing.containerPadding)
                .padding(.top, 16)
                .padding(.bottom, MSLayout.tabContentBottomInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerRelativeFrame(.horizontal)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .msBrandBackground()
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

    private var heroSection: some View {
        let item = SampleData.heroInspiration
        return ZStack(alignment: .bottomLeading) {
            RemoteImage(
                url: item.imageURL,
                alignment: .top,
                targetSize: CGSize(width: 400, height: 420)
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(5 / 6, contentMode: .fill)
            .clipped()

            MSGradient.heroOverlay

            VStack(alignment: .leading, spacing: 16) {
                MSTypography.label(item.subtitle)
                    .foregroundStyle(.white.opacity(0.85))
                MSTypography.displayMobile(item.title)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                PillButton(title: L10n.startDrawing, icon: "paintbrush.fill", style: .glass) {
                    appStore.clearEditingSession()
                    appStore.applyInspiration(
                        CanvasMediumSelection(name: item.title, kind: .inspiration, imageURL: item.imageURL)
                    )
                    selectedTab?.wrappedValue = .canvas
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
        .msCardShadow(colorScheme)
    }

    private var mediumsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                MSTypography.headline(L10n.mediums)
                    .foregroundStyle(MSColor.primary)
                Spacer()
                Button {
                    selectedTab?.wrappedValue = .workshop
                } label: {
                    Image(systemName: "arrow.forward")
                        .foregroundStyle(MSColor.onSurfaceVariant)
                }
                .buttonStyle(PressScaleStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(SampleData.mediums) { medium in
                        VStack(spacing: 12) {
                            ZStack(alignment: .topTrailing) {
                                RemoteImage(
                                    url: medium.imageURL,
                                    alignment: .top,
                                    targetSize: CGSize(width: 160, height: 160)
                                )
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
                                .shadow(color: MSColor.primary.opacity(0.08), radius: 6, y: 3)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    appStore.clearEditingSession()
                                    appStore.applyInspiration(CanvasMediumSelection(name: medium.name, kind: medium.kind, imageURL: medium.imageURL))
                                    selectedTab?.wrappedValue = .canvas
                                }
                                .overlay(alignment: .topLeading) {
                                    FavoriteToggleButton(
                                        isFavorite: appStore.isMediumFavorite(medium.imageURL)
                                    ) {
                                        _ = appStore.toggleMediumFavorite(medium.imageURL)
                                    }
                                    .padding(8)
                                }

                                Button {
                                    previewMedium = medium
                                } label: {
                                    Image(systemName: "eye.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(Circle().fill(Color.black.opacity(0.35)))
                                        .padding(4)
                                }
                                .buttonStyle(.borderless)
                                .padding(6)
                                .accessibilityLabel(L10n.mediumPreview)
                            }

                            MSTypography.label(medium.name)
                                .foregroundStyle(MSColor.onSurfaceVariant)
                                .lineLimit(1)
                        }
                        .frame(width: 160)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(medium.name)
                    }
                }
            }
            .scrollClipDisabled(false)
        }
    }

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                MSTypography.headline(L10n.communityCreations)
                    .foregroundStyle(MSColor.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isSorted.toggle()
                        communityArts = isSorted
                            ? SampleData.communityArts.sorted { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
                            : SampleData.communityArts
                        appStore.showToast(L10n.sortApplied, style: .info)
                    }
                } label: {
                    Image(systemName: isSorted ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(MSColor.primary)
                        .padding(8)
                        .background {
                            Circle()
                                .fill(MSColor.blush.opacity(0.3))
                                .background(.ultraThinMaterial, in: Circle())
                        }
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(L10n.communityCreations)
            }

            MasonryGrid(items: communityArts) { art in
                CommunityArtCard(art: art) {
                    selectedCommunityArt = art
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MediumPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var appStore
    let medium: MediumItem
    var onUse: (() -> Void)?

    private var preset: CanvasMediumPreset {
        CanvasMediumPreset.forKind(medium.kind)
    }

    var body: some View {
        MSPreviewSheetLayout(
            title: L10n.mediumPreview,
            primaryTitle: onUse == nil ? nil : L10n.useMedium,
            primaryAction: onUse == nil ? nil : {
                onUse?()
                dismiss()
            },
            hero: {
                MSPreviewHeroImage(url: medium.imageURL, aspectRatio: 1)
            },
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    MSPreviewInfoCard(title: medium.name, subtitle: preset.description)

                    HStack(spacing: 8) {
                        presetChip(L10n.strokeSize(Int(preset.strokeWidth)))
                        if preset.strokeOpacity < 1 {
                            presetChip(L10n.mediumOpacity(Int(preset.strokeOpacity * 100)))
                        }
                    }

                    presetPalettePreview
                }
            },
            trailing: {
                FavoriteToggleButton(
                    isFavorite: appStore.isMediumFavorite(medium.imageURL),
                    onDarkBackground: false
                ) {
                    _ = appStore.toggleMediumFavorite(medium.imageURL)
                }
            }
        )
        .msPreviewSheetStyle()
    }

    private func presetChip(_ text: String) -> some View {
        MSTypography.label(text)
            .foregroundStyle(MSColor.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(MSColor.primaryContainer.opacity(0.45)))
    }

    private var presetPalettePreview: some View {
        GlassPanel(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                MSTypography.label(L10n.mediumPalette)
                    .foregroundStyle(MSColor.onSurfaceVariant)
                HStack(spacing: 8) {
                    ForEach(Array(preset.colors.enumerated()), id: \.offset) { _, color in
                        MSColorSwatch(color: color, size: 26, showsCheckmark: false)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}

struct CommunityArtCard: View {
    @Environment(AppStore.self) private var appStore
    let art: CommunityArt
    let onOpen: () -> Void

    var body: some View {
        SizedRemoteImage(url: art.imageURL, contentMode: .fill)
            .aspectRatio(art.aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                FavoriteToggleButton(
                    isFavorite: appStore.isCommunityFavorite(art.imageURL)
                ) {
                    _ = appStore.toggleCommunityFavorite(art.imageURL)
                }
                .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                MSTypography.label(art.author)
                    .foregroundStyle(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .bottom, endPoint: .top)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .onTapGesture(perform: onOpen)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct MasonryGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    private var leftColumnItems: [Item] {
        items.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element)
    }

    private var rightColumnItems: [Item] {
        items.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element)
    }

    var body: some View {
        HStack(alignment: .top, spacing: MSSpacing.gutter) {
            LazyVStack(spacing: MSSpacing.gutter) {
                ForEach(leftColumnItems) { item in
                    content(item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)

            LazyVStack(spacing: MSSpacing.gutter) {
                ForEach(rightColumnItems) { item in
                    content(item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppStore())
        .environment(\.selectedTab, .constant(.home))
}
