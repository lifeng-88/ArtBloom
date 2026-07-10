import SwiftUI
import PhotosUI

struct WorkshopView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.selectedTab) private var selectedTab

    @State private var templates = SampleData.styleTemplates()
    @State private var selectedTemplateIndex = 1
    @State private var uploadedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewTemplate: StyleTemplate?
    @State private var showAllTemplates = false

    var body: some View {
        ZStack(alignment: .top) {
            MSBrandBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: MSLayout.topBarHeight + 16)

                    headerSection
                        .padding(.horizontal, MSSpacing.containerPadding)
                        .padding(.bottom, 40)

                    inputCards
                        .padding(.horizontal, MSSpacing.containerPadding)
                        .padding(.bottom, 48)

                    templatesSection
                        .padding(.horizontal, MSSpacing.containerPadding)
                        .padding(.bottom, 24)
                }
                .msScrollContentWidth()
            }
            .msPageScroll()

            GlassTopBar(title: L10n.appName, icon: "paintpalette.fill") {
                Button {
                    selectedTab?.wrappedValue = .studio
                } label: {
                    ProfileAvatarView()
                }
                .buttonStyle(PressScaleStyle())
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            transformButtonBar
        }
        .onChange(of: selectedPhotoItem) { _, item in
            loadPhoto(from: item)
        }
        .sheet(item: $previewTemplate) { template in
            TemplatePreviewSheet(template: template) {
                if let index = templates.firstIndex(where: { $0.id == template.id }) {
                    selectTemplate(at: index)
                }
                previewTemplate = nil
            }
        }
        .sheet(isPresented: $showAllTemplates) {
            AllTemplatesSheet(
                templates: templates,
                selectedIndex: $selectedTemplateIndex,
                onPreview: { template in
                    previewTemplate = template
                },
                onSelect: { index in
                    selectTemplate(at: index)
                }
            )
        }
    }

    private func selectTemplate(at index: Int) {
        guard templates.indices.contains(index) else { return }
        selectedTemplateIndex = index
        let template = templates[index]
        appStore.applyMedium(CanvasMediumSelection(name: template.name, kind: template.kind, imageURL: template.imageURL))
        appStore.showToast(L10n.templateSelected)
        CanvasHaptics.light()
    }

    private var selectedTemplate: StyleTemplate? {
        guard templates.indices.contains(selectedTemplateIndex) else { return nil }
        return templates[selectedTemplateIndex]
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MSTypography.headline(L10n.templateWorkshop)
                .foregroundStyle(MSColor.primary)
            MSTypography.body(L10n.workshopSubtitle)
                .foregroundStyle(MSColor.onSurfaceVariant)

            HStack(spacing: 12) {
                workshopStep(icon: "photo.on.rectangle", label: L10n.uploadPhoto)
                Image(systemName: "arrow.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.5))
                workshopStep(icon: "paintpalette.fill", label: L10n.styleTemplates)
                Image(systemName: "arrow.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.5))
                workshopStep(icon: "paintbrush.fill", label: L10n.tabCanvas)
            }
            .padding(.top, 4)
        }
    }

    private func workshopStep(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(MSColor.primary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(MSColor.primaryContainer.opacity(0.45)))
            MSTypography.label(label)
                .foregroundStyle(MSColor.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var inputCards: some View {
        VStack(spacing: 24) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                GlassPanel(cornerRadius: MSSpacing.cardRadius) {
                    Group {
                        if let uploadedImage {
                            Image(uiImage: uploadedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } else {
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(MSColor.surfaceContainerLowest)
                                    .frame(width: 64, height: 64)
                                    .overlay {
                                        Image(systemName: "arrow.up.doc.fill")
                                            .font(.title)
                                            .foregroundStyle(MSColor.primary)
                                    }
                                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                                MSTypography.headline(L10n.uploadPhoto)
                                    .foregroundStyle(MSColor.primary)
                                MSTypography.label(L10n.uploadPhotoHint)
                                    .foregroundStyle(MSColor.onSurfaceVariant)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .padding(uploadedImage == nil ? 32 : 0)
                }
            }
            .buttonStyle(PressScaleStyle())
            .overlay(alignment: .topTrailing) {
                if uploadedImage != nil {
                    Button {
                        uploadedImage = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, MSColor.primary)
                    }
                    .padding(12)
                }
            }
        }
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    MSTypography.headline(L10n.styleTemplates)
                        .foregroundStyle(MSColor.primary)
                    MSTypography.label(L10n.styleTemplatesHint)
                        .foregroundStyle(MSColor.onSurfaceVariant)
                }
                Spacer()
                Button {
                    showAllTemplates = true
                } label: {
                    HStack(spacing: 4) {
                        MSTypography.label(L10n.viewAll)
                            .foregroundStyle(MSColor.primary)
                        Image(systemName: "arrow.forward")
                            .font(.caption)
                            .foregroundStyle(MSColor.primary)
                    }
                }
                .buttonStyle(PressScaleStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(templates.indices, id: \.self) { index in
                        TemplateCard(
                            template: templates[index],
                            isSelected: selectedTemplateIndex == index,
                            onPreview: {
                                previewTemplate = templates[index]
                            },
                            onSelect: {
                                selectTemplate(at: index)
                            }
                        )
                    }
                }
                .padding(.bottom, 8)
            }
            .scrollClipDisabled(false)
            .scrollTargetLayout()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var transformButtonBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.15)
            transformButton
                .padding(.horizontal, MSSpacing.containerPadding)
                .padding(.top, 12)
                .padding(.bottom, MSLayout.fabBottomInset)
        }
        .background {
            MSColor.roseMist.opacity(0.94)
                .background(.ultraThinMaterial)
        }
    }

    private var transformButton: some View {
        PillButton(
            title: L10n.transform,
            icon: "paintbrush.pointed.fill",
            style: .primary,
            fullWidth: true,
            action: importToCanvas
        )
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
        .disabled(uploadedImage == nil)
        .opacity(uploadedImage == nil ? 0.5 : 1)
        .accessibilityLabel(L10n.transform)
    }

    private func importToCanvas() {
        guard let uploadedImage else {
            appStore.showToast(L10n.uploadPhotoHint, style: .info)
            CanvasHaptics.light()
            return
        }
        appStore.pendingCanvasBackground = uploadedImage
        appStore.clearEditingSession()
        if let active = selectedTemplate {
            appStore.applyMedium(CanvasMediumSelection(name: active.name, kind: active.kind, imageURL: active.imageURL))
        }
        appStore.showToast(L10n.transformReadyHint)
        CanvasHaptics.medium()
        selectedTab?.wrappedValue = .canvas
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        PhotoImportHelper.loadImage(from: item) { image in
            if let image {
                uploadedImage = image
                appStore.showToast(L10n.photoSelected)
            } else if item != nil {
                appStore.showToast(L10n.photoLoadFailed, style: .error)
            }
        }
    }
}

struct TemplateCard: View {
    enum Layout {
        case carousel
        case grid
    }

    let template: StyleTemplate
    let isSelected: Bool
    var layout: Layout = .carousel
    var onPreview: () -> Void = {}
    let onSelect: () -> Void

    private var imageAspectRatio: CGFloat { 4 / 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: layout == .grid ? 12 : 16) {
            imageSection
            textSection
                .onTapGesture(perform: onSelect)
        }
        .frame(width: layout == .carousel ? 200 : nil)
        .frame(maxWidth: layout == .grid ? .infinity : nil, alignment: .leading)
        .accessibilityLabel("\(template.name), \(isSelected ? L10n.active : L10n.templatePreview)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: L10n.useTemplate, onSelect)
        .accessibilityAction(named: L10n.templatePreview, onPreview)
    }

    private var imageSection: some View {
        templateImage
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .clipShape(RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MSSpacing.cardRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? MSColor.primary : MSColor.outlineVariant.opacity(0.35),
                        lineWidth: isSelected ? 3 : 1
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onPreview) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.35)))
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .padding(6)
                .accessibilityLabel(L10n.templatePreview)
            }
            .overlay(alignment: .bottomLeading) {
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        MSTypography.label(L10n.active)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(MSColor.primary))
                    .padding(10)
                }
            }
    }

    @ViewBuilder
    private var templateImage: some View {
        let decodeSize = layout == .carousel
            ? CGSize(width: 200, height: 250)
            : CGSize(width: 400, height: 500)

        if layout == .carousel {
            RemoteImage(
                url: template.imageURL,
                alignment: .top,
                targetSize: decodeSize
            )
            .frame(width: 200, height: 250)
        } else {
            Color.clear
                .aspectRatio(imageAspectRatio, contentMode: .fit)
                .overlay {
                    RemoteImage(
                        url: template.imageURL,
                        alignment: .top,
                        targetSize: decodeSize
                    )
                }
                .frame(maxWidth: .infinity)
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.system(size: layout == .grid ? 16 : 18, weight: .bold))
                .foregroundStyle(MSColor.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            MSTypography.label(template.description)
                .foregroundStyle(MSColor.onSurfaceVariant)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: layout == .grid ? 44 : nil, alignment: .topLeading)
        .padding(.horizontal, 2)
    }
}

struct TemplatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: StyleTemplate
    let onUse: () -> Void

    var body: some View {
        MSPreviewSheetLayout(
            title: L10n.templatePreview,
            primaryTitle: L10n.useTemplate,
            primaryAction: {
                onUse()
                dismiss()
            },
            hero: {
                MSPreviewHeroImage(url: template.imageURL)
            },
            content: {
                MSPreviewInfoCard(title: template.name, subtitle: template.description)
            }
        )
        .msPreviewSheetStyle()
    }
}

struct AllTemplatesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [StyleTemplate]
    @Binding var selectedIndex: Int
    let onPreview: (StyleTemplate) -> Void
    let onSelect: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: MSSpacing.gutter),
        GridItem(.flexible(), spacing: MSSpacing.gutter)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(templates.indices, id: \.self) { index in
                        TemplateCard(
                            template: templates[index],
                            isSelected: selectedIndex == index,
                            layout: .grid,
                            onPreview: {
                                onPreview(templates[index])
                            },
                            onSelect: {
                                onSelect(index)
                            }
                        )
                    }
                }
                .padding(.horizontal, MSSpacing.containerPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .msBrandBackground()
            .navigationTitle(L10n.styleTemplates)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .msLargeSheetStyle()
    }
}

struct NotificationsSheet: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appStore.notifications.isEmpty {
                    MSEmptyState(icon: "bell.slash", message: L10n.noNotifications)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(appStore.notifications) { notification in
                                Button {
                                    appStore.markNotificationRead(notification.id)
                                } label: {
                                    GlassPanel {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                MSTypography.label(notification.title)
                                                    .foregroundStyle(MSColor.onSurface)
                                                Spacer()
                                                if !notification.isRead {
                                                    Circle()
                                                        .fill(MSColor.primary)
                                                        .frame(width: 8, height: 8)
                                                }
                                            }
                                            MSTypography.body(notification.message)
                                                .foregroundStyle(MSColor.onSurfaceVariant)
                                                .multilineTextAlignment(.leading)
                                            MSTypography.label(
                                                L10n.formatDate(notification.createdAt)
                                            )
                                            .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.7))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(MSSpacing.containerPadding)
                    }
                }
            }
            .msBrandBackground()
            .navigationTitle(L10n.notifications)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.done) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !appStore.notifications.isEmpty {
                        Button(L10n.markAllRead) {
                            appStore.markAllNotificationsRead()
                        }
                    }
                }
            }
        }
        .msLargeSheetStyle()
    }
}

#Preview {
    WorkshopView()
        .environment(AppStore())
}
