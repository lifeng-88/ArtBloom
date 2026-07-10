import SwiftUI

struct StudioSettingsView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var cacheSizeLabel = "—"
    @State private var showClearCacheConfirm = false
    @State private var showClearFavoritesConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MSSectionSpacing.tight) {
                    settingsSectionHeader(L10n.settingsPreferences)

                    GlassPanel {
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "moon.fill",
                                title: L10n.settingsDarkMode,
                                isOn: Binding(
                                    get: { appStore.isDarkModeEnabled },
                                    set: { appStore.setDarkModeEnabled($0) }
                                )
                            )

                            settingsDivider

                            ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                                Button {
                                    appStore.setLanguage(language)
                                    CanvasHaptics.light()
                                } label: {
                                    SettingsSelectionRow(
                                        icon: "globe",
                                        title: languageTitle(language),
                                        isSelected: appStore.appLanguage == language
                                    )
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                if index < AppLanguage.allCases.count - 1 {
                                    settingsDivider
                                }
                            }
                        }
                    }

                    MSTypography.label(L10n.languageSettingsHint)
                        .foregroundStyle(MSColor.onSurfaceVariant)
                        .padding(.horizontal, 4)

                    settingsSectionHeader(L10n.settingsStorage)

                    GlassPanel {
                        VStack(spacing: 0) {
                            SettingsInfoRow(
                                icon: "internaldrive",
                                title: L10n.settingsCacheSize,
                                value: cacheSizeLabel
                            )

                            if appStore.hasInspirationFavorites {
                                settingsDivider
                                SettingsInfoRow(
                                    icon: "sparkles",
                                    title: L10n.settingsInspirationFavorites,
                                    value: "\(appStore.favoriteMediumURLs.count + appStore.favoriteCommunityURLs.count)"
                                )
                            }

                            settingsDivider

                            SettingsActionRow(
                                icon: "trash",
                                title: L10n.settingsClearCache,
                                role: .destructive
                            ) {
                                showClearCacheConfirm = true
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if appStore.hasInspirationFavorites {
                                settingsDivider
                                SettingsActionRow(
                                    icon: "heart.slash",
                                    title: L10n.settingsClearInspirationFavorites,
                                    role: .destructive
                                ) {
                                    showClearFavoritesConfirm = true
                                }
                            }
                        }
                    }

                    settingsSectionHeader(L10n.settingsAbout)

                    #if DEBUG
                    if ArtBloomBSideManager.shared.canSwitchToBSide {
                        GlassPanel {
                            VStack(spacing: 0) {
                                if ArtBloomBSideManager.shared.isShowingWeb {
                                    SettingsActionRow(
                                        icon: "arrow.uturn.backward",
                                        title: L10n.settingsBSideClose
                                    ) {
                                        ArtBloomBSideManager.shared.showSurfaceA()
                                        dismiss()
                                    }
                                } else {
                                    SettingsActionRow(
                                        icon: "globe",
                                        title: L10n.settingsBSideOpen
                                    ) {
                                        Task {
                                            await ArtBloomBSideManager.shared.switchToBSide()
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }

                        MSTypography.label(L10n.settingsBSideHint)
                            .foregroundStyle(MSColor.onSurfaceVariant)
                            .padding(.horizontal, 4)
                    }
                    #endif

                    GlassPanel {
                        VStack(spacing: 0) {
                            SettingsInfoRow(
                                icon: "info.circle",
                                title: L10n.settingsVersion,
                                value: appVersionLabel
                            )

                            settingsDivider

                            NavigationLink {
                                LegalDocumentView(kind: .privacyPolicy)
                            } label: {
                                SettingsSelectionRow(
                                    icon: "hand.raised.fill",
                                    title: L10n.privacyPolicy,
                                    showsChevron: true
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            settingsDivider

                            NavigationLink {
                                LegalDocumentView(kind: .termsOfService)
                            } label: {
                                SettingsSelectionRow(
                                    icon: "doc.text.fill",
                                    title: L10n.termsOfService,
                                    showsChevron: true
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    MSTypography.label(L10n.unsplashAttribution)
                        .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.85))
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
                .padding(MSSpacing.containerPadding)
            }
            .msBrandBackground()
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .task { refreshCacheSize() }
            .confirmationDialog(
                L10n.settingsClearCacheConfirm,
                isPresented: $showClearCacheConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.settingsClearCache, role: .destructive) {
                    appStore.clearImageCaches()
                    refreshCacheSize()
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .confirmationDialog(
                L10n.settingsClearInspirationFavoritesConfirm,
                isPresented: $showClearFavoritesConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.settingsClearInspirationFavorites, role: .destructive) {
                    appStore.clearInspirationFavorites()
                }
                Button(L10n.cancel, role: .cancel) {}
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var settingsDivider: some View {
        Divider().opacity(0.2).padding(.leading, 52)
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return L10n.settingsVersionValue(version, build: build)
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        MSTypography.label(title)
            .foregroundStyle(MSColor.onSurfaceVariant)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }

    private func refreshCacheSize() {
        let bytes = ImageCache.shared.approximateDiskCacheByteCount()
        cacheSizeLabel = L10n.formatByteCount(bytes)
    }

    private func languageTitle(_ language: AppLanguage) -> String {
        switch language {
        case .system: return L10n.languageSystem
        case .en: return L10n.languageEnglish
        case .zhHans: return L10n.languageZhHans
        case .zhHant: return L10n.languageZhHant
        }
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(MSColor.primary)
                .frame(width: 24)
            MSTypography.body(title)
                .foregroundStyle(MSColor.onSurface)
            Spacer(minLength: 0)
            MSTypography.label(value)
                .foregroundStyle(MSColor.onSurfaceVariant)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(MSColor.primary)
                    .frame(width: 24)
                MSTypography.body(title)
                    .foregroundStyle(MSColor.onSurface)
            }
        }
        .tint(MSColor.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsSelectionRow: View {
    let icon: String
    let title: String
    var isSelected: Bool = false
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(MSColor.primary)
                .frame(width: 24)
            MSTypography.body(title)
                .foregroundStyle(MSColor.onSurface)
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MSColor.primary)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct SettingsActionRow: View {
    let icon: String
    let title: String
    var role: SettingsActionRole = .normal
    let action: () -> Void

    enum SettingsActionRole {
        case normal
        case destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(role == .destructive ? .red : MSColor.primary)
                    .frame(width: 24)
                MSTypography.body(title)
                    .foregroundStyle(role == .destructive ? .red : MSColor.onSurface)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
