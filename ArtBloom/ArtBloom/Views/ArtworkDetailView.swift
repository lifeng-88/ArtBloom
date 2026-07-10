import SwiftUI

struct ArtworkDetailView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.selectedTab) private var selectedTab

    let artworkID: UUID

    @State private var title: String = ""
    @State private var showDeleteAlert = false

    private var artwork: SavedArtwork? {
        appStore.artworkStore.artwork(with: artworkID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let artwork {
                        LocalArtworkImage(
                            url: appStore.artworkStore.imageURL(for: artwork),
                            contentMode: .fit
                        )
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    } else {
                        MSColor.surfaceContainerHigh
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        TextField(L10n.renameArtwork, text: $title)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(MSColor.onSurface)
                            .onSubmit { saveTitle() }

                        if let artwork {
                            MSTypography.label(artwork.subtitle)
                                .foregroundStyle(MSColor.onSurfaceVariant)
                            MSTypography.label(formattedDate(artwork.createdAt))
                                .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.7))
                        }
                    }

                    actionButtons
                }
                .padding(MSSpacing.containerPadding)
            }
            .msBrandBackground()
            .navigationTitle(L10n.artworkDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.done) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let artwork, !artwork.isDraft {
                        Button {
                            _ = appStore.toggleFavoriteArtwork(artworkID)
                        } label: {
                            Image(systemName: artwork.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(artwork.isFavorite ? MSColor.primary : MSColor.onSurfaceVariant)
                                .symbolEffect(.bounce, value: artwork.isFavorite)
                        }
                        .accessibilityLabel(artwork.isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites)
                    }
                }
            }
            .onAppear {
                if let artwork {
                    title = artwork.title
                }
            }
            .alert(L10n.deleteConfirmTitle, isPresented: $showDeleteAlert) {
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.delete, role: .destructive) {
                    appStore.artworkStore.delete(artworkID)
                    appStore.showToast(L10n.deletedSuccess)
                    dismiss()
                }
            } message: {
                Text(L10n.deleteConfirmMessage)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if let artwork {
            VStack(spacing: 12) {
                Button {
                    appStore.beginEditingArtwork(artwork.id)
                    dismiss()
                    selectedTab?.wrappedValue = .canvas
                } label: {
                    actionRow(icon: "paintbrush.pointed.fill", label: L10n.continueEditing)
                }
                .buttonStyle(PressScaleStyle())

                if artwork.isDraft {
                    Button {
                        appStore.artworkStore.promoteDraft(artwork.id)
                        appStore.showToast(L10n.publishedSuccess)
                    } label: {
                        actionRow(icon: "checkmark.seal.fill", label: L10n.publishArtwork)
                    }
                    .buttonStyle(PressScaleStyle())
                }

                if !artwork.isDraft {
                    Button {
                        _ = appStore.toggleFavoriteArtwork(artwork.id)
                    } label: {
                        actionRow(
                            icon: artwork.isFavorite ? "heart.fill" : "heart",
                            label: artwork.isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites,
                            tint: artwork.isFavorite ? MSColor.primary : nil
                        )
                    }
                    .buttonStyle(PressScaleStyle())
                }

                ShareLink(
                    item: SharedArtworkImage(url: appStore.artworkStore.imageURL(for: artwork)),
                    preview: SharePreview(artwork.title, icon: "photo")
                ) {
                    actionRow(icon: "square.and.arrow.up", label: L10n.share)
                }

                Button {
                    saveTitle()
                } label: {
                    actionRow(icon: "pencil", label: L10n.renameArtwork)
                }
                .buttonStyle(PressScaleStyle())

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    actionRow(icon: "trash", label: L10n.delete, destructive: true)
                }
                .buttonStyle(PressScaleStyle())
            }
        }
    }

    private func actionRow(icon: String, label: String, destructive: Bool = false, tint: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            MSTypography.body(label)
            Spacer()
        }
        .foregroundStyle(destructive ? .red : (tint ?? MSColor.onSurface))
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous)
                .fill(destructive ? Color.red.opacity(0.08) : MSColor.surfaceContainerLow.opacity(0.5))
        }
    }

    private func saveTitle() {
        if appStore.artworkStore.updateTitle(artworkID, title: title) {
            appStore.showToast(L10n.renamedSuccess)
        } else {
            appStore.showToast(L10n.titleEmpty, style: .error)
            if let artwork {
                title = artwork.title
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        L10n.formatDate(date)
    }
}

struct CommunityDetailView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.selectedTab) private var selectedTab

    let art: CommunityArt

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SizedRemoteImage(url: art.imageURL, contentMode: .fit)
                        .aspectRatio(art.aspectRatio, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        MSTypography.headline(art.author)
                            .foregroundStyle(MSColor.primary)
                        MSTypography.body(L10n.communityDetailHint)
                            .foregroundStyle(MSColor.onSurfaceVariant)
                    }

                    Button {
                        appStore.clearEditingSession()
                        appStore.applyInspiration(CanvasMediumSelection(name: art.author, kind: .inspiration, imageURL: art.imageURL))
                        dismiss()
                        selectedTab?.wrappedValue = .canvas
                    } label: {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                            MSTypography.label(L10n.getInspired)
                        }
                        .foregroundStyle(MSColor.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(MSColor.primary))
                    }
                    .buttonStyle(PressScaleStyle())
                }
                .padding(MSSpacing.containerPadding)
            }
            .msBrandBackground()
            .navigationTitle(L10n.communityDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    FavoriteToggleButton(
                        isFavorite: appStore.isCommunityFavorite(art.imageURL),
                        onDarkBackground: false
                    ) {
                        _ = appStore.toggleCommunityFavorite(art.imageURL)
                    }
                }
            }
        }
    }
}
