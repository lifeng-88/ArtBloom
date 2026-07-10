import SwiftUI
import PhotosUI
import UIKit

struct DrawingCanvasView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.selectedTab) private var selectedTab

    @State private var viewModel = CanvasViewModel()
    @State private var selectedTool: DrawingTool = .brush
    @State private var selectedColor: Color = MSColor.primary
    @State private var strokeWidth: Double = CanvasMediumDefaults.strokeWidth
    @State private var strokeOpacity: Double = CanvasMediumDefaults.strokeOpacity
    @State private var eraserScale: Double = CanvasMediumDefaults.eraserScale
    @State private var strokeRange: ClosedRange<Double> = CanvasMediumDefaults.strokeRange
    @State private var canvasBackground: Color = CanvasMediumDefaults.canvasBackground
    @State private var mediumColors: [Color]?
    @State private var activeMedium: CanvasMediumSelection?
    @State private var showMediumBanner = false
    @State private var showMediumPreview = false
    @State private var showStageSheet = false
    @State private var showLayersSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var zoomScale: CGFloat = 1
    @State private var baseZoomScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var basePanOffset: CGSize = .zero
    @State private var isFullscreenDrawing = false

    private var canvasCornerRadius: CGFloat {
        isFullscreenDrawing ? 0 : 20
    }

    private enum CanvasLayout {
        static let edgeInset: CGFloat = 8
        static let topBarHeight: CGFloat = 44
    }

    private enum DrawingTool: String, CaseIterable {
        case brush, eraser, hand, layers

        var icon: String {
            switch self {
            case .brush: return "pencil.tip"
            case .eraser: return "eraser.fill"
            case .hand: return "hand.draw"
            case .layers: return "square.stack.3d.up"
            }
        }

        var label: String {
            switch self {
            case .brush: return L10n.brush
            case .eraser: return L10n.eraser
            case .hand: return L10n.canvasPan
            case .layers: return L10n.layers
            }
        }
    }

    private var palette: [(Color, String)] {
        let colors = mediumColors ?? CanvasMediumDefaults.palette
        return colors.enumerated().map { index, color in
            (color, "color-\(index)")
        }
    }

    private var isCustomColorSelected: Bool {
        selectedTool == .brush && !palette.contains { MSColorMatch.matches($0.0, selectedColor) }
    }

    private func isPresetColorSelected(_ color: Color) -> Bool {
        selectedTool == .brush && MSColorMatch.matches(color, selectedColor)
    }

    private var canDraw: Bool {
        selectedTool != .layers && selectedTool != .hand && zoomScale <= 1.05
    }

    private var isPanningCanvas: Bool {
        selectedTool == .hand || zoomScale > 1.05
    }

    private var isZoomed: Bool {
        abs(zoomScale - 1) > 0.05 || abs(panOffset.width) > 1 || abs(panOffset.height) > 1
    }

    var body: some View {
        let _ = appStore.appLanguage
        Group {
            if isFullscreenDrawing {
                fullscreenLayout
            } else {
                standardLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .msBrandBackground()
        .sheet(isPresented: $showStageSheet) { stageSheet }
        .sheet(isPresented: $showLayersSheet) { layersSheet }
        .sheet(isPresented: $showMediumPreview) {
            if let medium = activeMedium {
                MediumPreviewSheet(medium: medium.previewItem())
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            loadPhoto(from: item)
        }
        .onChange(of: selectedTool) { _, tool in
            if tool == .layers {
                showLayersSheet = true
            } else {
                CanvasHaptics.light()
            }
        }
        .onChange(of: selectedColor) { _, _ in
            if selectedTool == .eraser {
                selectedTool = .brush
            } else if selectedTool == .hand {
                selectedTool = .brush
            }
        }
        .onChange(of: isFullscreenDrawing) { _, fullscreen in
            appStore.canvasFullscreen = fullscreen
        }
        .onAppear {
            applyEditingSession()
            applyPendingMedium()
        }
        .onDisappear {
            appStore.canvasFullscreen = false
        }
        .onChange(of: appStore.editingArtworkID) { _, _ in
            applyEditingSession()
        }
        .onChange(of: appStore.pendingMedium) { _, _ in
            applyPendingMedium()
        }
        .onChange(of: appStore.pendingCanvasBackground) { _, image in
            guard image != nil, appStore.editingArtworkID == nil else { return }
            applyPendingBackground()
        }
        .onChange(of: viewModel.canvasSize) { _, _ in
            viewModel.restorePendingSessionIfNeeded()
        }
    }

    private var standardLayout: some View {
        VStack(spacing: 0) {
            canvasTopBar

            if showMediumBanner, let medium = activeMedium {
                mediumHintBanner(medium)
            }

            if appStore.editingArtworkID != nil {
                editingModeBanner
            }

            canvasArea
                .padding(.horizontal, CanvasLayout.edgeInset)
                .padding(.top, 4)
                .layoutPriority(1)

            creativeTray
                .padding(.top, 4)
                .padding(.bottom, 2)
        }
    }

    private var fullscreenLayout: some View {
        canvasArea
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                fullscreenTopBar
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                fullscreenBottomTray
            }
    }

    private var fullscreenTopBar: some View {
        HStack(spacing: 10) {
            iconToolBarButton(
                icon: "arrow.down.right.and.arrow.up.left",
                label: L10n.exitFullscreen,
                action: toggleFullscreen
            )

            iconToolBarButton(
                icon: "arrow.uturn.backward",
                label: L10n.undo,
                disabled: viewModel.paths.isEmpty,
                action: undo
            )
            iconToolBarButton(
                icon: "arrow.uturn.forward",
                label: L10n.redo,
                disabled: viewModel.redoStack.isEmpty,
                action: redo
            )

            iconToolBarButton(
                icon: "trash",
                label: L10n.clearCanvas,
                disabled: !canClearCanvas,
                action: clearCanvas
            )

            Spacer(minLength: 0)

            canvasSaveActions()

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minHeight: 48)
        .frame(maxWidth: .infinity)
        .background {
            MSColor.surface.opacity(0.92)
                .background(.ultraThinMaterial)
        }
    }

    private var fullscreenBottomTray: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(palette, id: \.1) { color, _ in
                        Button {
                            selectedColor = color
                            selectedTool = .brush
                            CanvasHaptics.light()
                        } label: {
                            MSColorSwatch(
                                color: color,
                                isSelected: isPresetColorSelected(color),
                                size: 30
                            )
                        }
                        .buttonStyle(PressScaleStyle())
                    }

                    MSCustomColorPickerButton(
                        selection: $selectedColor,
                        isSelected: isCustomColorSelected,
                        size: 30,
                        accessibilityLabel: L10n.customColor
                    )

                    Divider().frame(height: 24).opacity(0.3)

                    ForEach(DrawingTool.allCases, id: \.self) { tool in
                        Button {
                            selectedTool = tool
                        } label: {
                            Image(systemName: tool.icon)
                                .font(.body)
                                .foregroundStyle(selectedTool == tool ? MSColor.primary : MSColor.onSurfaceVariant)
                                .frame(width: 44, height: 44)
                                .background {
                                    if selectedTool == tool {
                                        Circle().fill(MSColor.primaryContainer.opacity(0.6))
                                    }
                                }
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityLabel(tool.label)
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.body)
                            .foregroundStyle(MSColor.onSurfaceVariant)
                            .frame(width: 44, height: 44)
                    }

                    Button { showStageSheet = true } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundStyle(MSColor.onSurfaceVariant)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PressScaleStyle())
                }
                .padding(.horizontal, 12)
            }

            HStack(spacing: 12) {
                Text(L10n.strokeSize(Int(strokeWidth)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MSColor.onSurfaceVariant)
                    .frame(width: 56, alignment: .leading)
                Slider(value: $strokeWidth, in: strokeRange)
                    .tint(MSColor.primary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .background {
            MSColor.surface.opacity(0.92)
                .background(.ultraThinMaterial)
        }
    }

    private func toggleFullscreen() {
        withAnimation(.easeOut(duration: 0.25)) {
            isFullscreenDrawing.toggle()
        }
        CanvasHaptics.medium()
    }

    private var editingModeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil.and.outline")
                .foregroundStyle(MSColor.primary)
            MSTypography.label(L10n.editingMode)
                .foregroundStyle(MSColor.onSurfaceVariant)
            Spacer()
            Button {
                appStore.clearEditingSession()
                viewModel.paths.removeAll()
                viewModel.redoStack.removeAll()
                viewModel.backgroundImage = nil
                resetCanvasView()
                selectedTab?.wrappedValue = .studio
            } label: {
                MSTypography.label(L10n.done)
                    .foregroundStyle(MSColor.primary)
            }
        }
        .padding(.horizontal, MSSpacing.containerPadding)
        .padding(.vertical, 8)
        .background(MSColor.primaryContainer.opacity(0.35))
    }

    private func applyEditingSession() {
        if appStore.editingArtworkID != nil {
            resetCanvasView()
            Task {
                if let restored = await viewModel.loadEditingSession(appStore: appStore) {
                    canvasBackground = restored
                }
            }
        } else {
            applyPendingBackground()
        }
    }

    private func applyPendingBackground() {
        _ = viewModel.applyPendingBackground(from: appStore)
    }

    private func applyPendingMedium() {
        guard let selection = appStore.pendingMedium else { return }
        appStore.pendingMedium = nil
        applyMediumSelection(selection)
    }

    private func applyMediumSelection(_ selection: CanvasMediumSelection) {
        let preset = CanvasMediumPreset.forKind(selection.kind)
        activeMedium = selection
        showMediumBanner = true
        mediumColors = preset.colors
        strokeWidth = preset.strokeWidth
        strokeOpacity = preset.strokeOpacity
        eraserScale = preset.eraserScale
        canvasBackground = preset.canvasBackground
        strokeRange = preset.strokeRange
        selectedColor = preset.colors.first ?? MSColor.primary
        selectedTool = .brush
        CanvasHaptics.light()
        appStore.showToast(L10n.mediumApplied)
    }

    private func resetMediumSettings() {
        activeMedium = nil
        showMediumBanner = false
        mediumColors = nil
        strokeWidth = CanvasMediumDefaults.strokeWidth
        strokeOpacity = CanvasMediumDefaults.strokeOpacity
        eraserScale = CanvasMediumDefaults.eraserScale
        canvasBackground = CanvasMediumDefaults.canvasBackground
        strokeRange = CanvasMediumDefaults.strokeRange
        selectedColor = MSColor.primary
        appStore.showToast(L10n.mediumReset)
    }

    private func mediumHintBanner(_ medium: CanvasMediumSelection) -> some View {
        let preset = CanvasMediumPreset.forKind(medium.kind)
        return HStack(spacing: 8) {
            Button {
                showMediumPreview = true
                CanvasHaptics.light()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(MSColor.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        MSTypography.label("\(L10n.mediumHint): \(medium.localizedName)")
                            .foregroundStyle(MSColor.onSurfaceVariant)
                        MSTypography.label(preset.description)
                            .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.75))
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.mediumPreview)

            Spacer(minLength: 0)

            Button {
                showMediumBanner = false
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(MSColor.onSurfaceVariant)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, MSSpacing.containerPadding)
        .padding(.vertical, 8)
        .background(MSColor.lavender.opacity(0.35))
    }

    private var canvasTopBar: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)

            iconToolBarButton(
                icon: "arrow.uturn.backward",
                label: L10n.undo,
                disabled: viewModel.paths.isEmpty,
                action: undo
            )
            iconToolBarButton(
                icon: "arrow.uturn.forward",
                label: L10n.redo,
                disabled: viewModel.redoStack.isEmpty,
                action: redo
            )

            iconToolBarButton(
                icon: "trash",
                label: L10n.clearCanvas,
                disabled: !canClearCanvas,
                action: clearCanvas
            )

            iconToolBarButton(
                icon: isFullscreenDrawing
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right",
                label: isFullscreenDrawing ? L10n.exitFullscreen : L10n.fullscreen,
                action: toggleFullscreen
            )

            canvasSaveActions()

        }
        .padding(.horizontal, CanvasLayout.edgeInset)
        .frame(minHeight: CanvasLayout.topBarHeight)
        .background {
            MSColor.roseMist.opacity(0.72)
                .background(.ultraThinMaterial)
        }
    }

    private var canSaveArtwork: Bool {
        !viewModel.isSaving && !(viewModel.paths.isEmpty && viewModel.backgroundImage == nil)
    }

    private var canClearCanvas: Bool {
        viewModel.currentPath != nil
            || !viewModel.paths.isEmpty
            || viewModel.backgroundImage != nil
    }

    private func canvasSaveActions() -> some View {
        HStack(spacing: 8) {
            Button {
                saveArtwork(isDraft: true)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption.weight(.semibold))
                    Text(L10n.saveDraft)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(MSColor.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(MSColor.primaryContainer.opacity(0.55)))
            }
            .buttonStyle(PressScaleStyle())
            .disabled(!canSaveArtwork)
            .accessibilityLabel(L10n.saveDraft)

            Button {
                saveArtwork(isDraft: false)
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.caption.weight(.semibold))
                        Text(L10n.save)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(MSColor.onPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(MSGradient.primary))
            }
            .buttonStyle(PressScaleStyle())
            .disabled(!canSaveArtwork)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(L10n.save)
        }
    }

    private func iconToolBarButton(
        icon: String,
        label: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(disabled ? MSColor.onSurfaceVariant.opacity(0.35) : MSColor.onSurfaceVariant)
                .frame(width: 36, height: 36)
                .background(Capsule().fill(MSColor.surfaceContainerLow.opacity(0.6)))
        }
        .buttonStyle(PressScaleStyle())
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    private var canvasArea: some View {
        GeometryReader { geo in
            canvasContent
                .scaleEffect(zoomScale)
                .offset(panOffset)
                .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: canvasCornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: canvasCornerRadius, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if isZoomed {
                    zoomResetButton
                }
            }
            .simultaneousGesture(magnificationGesture)
            .gesture(activeCanvasGesture(in: geo.size))
            .onAppear { viewModel.canvasSize = geo.size }
            .onChange(of: geo.size) { _, size in viewModel.canvasSize = size }
        }
        .frame(minHeight: isFullscreenDrawing ? 0 : 200)
    }

    private var canvasShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: canvasCornerRadius, style: .continuous)
    }

    private var canvasContent: some View {
        ZStack {
            canvasShape
                .fill(canvasBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: isFullscreenDrawing ? .clear : MSColor.primary.opacity(0.06), radius: 12, y: 4)
                .overlay {
                    if !isFullscreenDrawing {
                        canvasShape.strokeBorder(MSColor.glassBorder.opacity(0.45), lineWidth: 1)
                    }
                }

            if let image = viewModel.backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: isFullscreenDrawing ? .fill : .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(canvasShape)
            }

            CanvasGridPattern()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(canvasShape)
                .allowsHitTesting(false)
                .opacity(viewModel.backgroundImage == nil ? 1 : 0.35)

            PathsCanvas(paths: viewModel.paths, currentPath: viewModel.currentPath)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(canvasShape)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var zoomResetButton: some View {
        Button {
            resetCanvasView()
            CanvasHaptics.light()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                MSTypography.label(L10n.resetZoom)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(MSColor.onPrimaryContainer)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(MSColor.primaryContainer)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
        }
        .buttonStyle(PressScaleStyle())
        .padding(.trailing, isFullscreenDrawing ? 12 : 8)
        .padding(.bottom, isFullscreenDrawing ? 12 : 8)
        .accessibilityLabel(L10n.resetZoom)
    }

    private func activeCanvasGesture(in size: CGSize) -> AnyGesture<DragGesture.Value> {
        if isPanningCanvas {
            return AnyGesture(panGesture)
        }
        return AnyGesture(drawGesture(in: size))
    }

    private func drawGesture(in size: CGSize) -> AnyGesture<DragGesture.Value> {
        AnyGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard canDraw else { return }
                    let point = mapToCanvasCoordinates(value.location, in: size)
                    if viewModel.currentPath == nil {
                        CanvasHaptics.light()
                        viewModel.currentPath = DrawingPath(
                            points: [point],
                            color: selectedColor,
                            lineWidth: selectedTool == .eraser ? strokeWidth * eraserScale : strokeWidth,
                            opacity: selectedTool == .eraser ? 1 : strokeOpacity,
                            isEraser: selectedTool == .eraser
                        )
                    } else {
                        viewModel.currentPath?.points.append(point)
                    }
                }
                .onEnded { _ in
                    if let path = viewModel.currentPath {
                        viewModel.paths.append(path)
                        viewModel.redoStack.removeAll()
                        viewModel.currentPath = nil
                    }
                }
        )
    }

    private var panGesture: AnyGesture<DragGesture.Value> {
        AnyGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard isPanningCanvas else { return }
                    panOffset = CGSize(
                        width: basePanOffset.width + value.translation.width,
                        height: basePanOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    basePanOffset = panOffset
                }
        )
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoomScale = min(max(baseZoomScale * value, 1), 4)
            }
            .onEnded { _ in
                baseZoomScale = zoomScale
                if zoomScale <= 1.05 {
                    resetCanvasView()
                }
            }
    }

    private func mapToCanvasCoordinates(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let adjustedX = (point.x - panOffset.width - center.x) / zoomScale + center.x
        let adjustedY = (point.y - panOffset.height - center.y) / zoomScale + center.y
        return CGPoint(x: adjustedX, y: adjustedY)
    }

    private func resetCanvasView() {
        zoomScale = 1
        baseZoomScale = 1
        panOffset = .zero
        basePanOffset = .zero
    }

    private var creativeTray: some View {
        GlassPanel(cornerRadius: 18) {
            VStack(spacing: 6) {
                compactColorPalette

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(DrawingTool.allCases, id: \.self) { tool in
                            toolButton(tool)
                        }

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            secondaryTool(icon: "photo.on.rectangle", label: L10n.importLabel)
                        }

                        Button { showStageSheet = true } label: {
                            secondaryTool(icon: "gearshape", label: L10n.stage)
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }

                HStack(spacing: 8) {
                    Text(L10n.size)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.7))
                    Slider(value: $strokeWidth, in: strokeRange)
                        .tint(MSColor.primary)
                    Text(L10n.strokeSize(Int(strokeWidth)))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.7))
                        .frame(width: 48, alignment: .trailing)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, CanvasLayout.edgeInset)
    }

    private var compactColorPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(palette, id: \.1) { color, _ in
                    Button {
                        selectedColor = color
                        selectedTool = .brush
                        CanvasHaptics.light()
                    } label: {
                        MSColorSwatch(
                            color: color,
                            isSelected: isPresetColorSelected(color),
                            size: 28
                        )
                    }
                    .buttonStyle(PressScaleStyle())
                }

                MSCustomColorPickerButton(
                    selection: $selectedColor,
                    isSelected: isCustomColorSelected,
                    size: 28,
                    accessibilityLabel: L10n.customColor
                )
            }
            .padding(.vertical, 2)
        }
    }

    private var stageSheet: some View {
        NavigationStack {
            List {
                Section(L10n.canvasBackgroundColor) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(CanvasBackgroundPresets.options.enumerated()), id: \.offset) { _, color in
                                Button {
                                    applyCanvasBackground(color)
                                } label: {
                                    canvasBackgroundSwatch(
                                        color: color,
                                        isSelected: colorsMatch(canvasBackground, color)
                                    )
                                }
                                .buttonStyle(PressScaleStyle())
                            }

                            ColorPicker(selection: $canvasBackground, supportsOpacity: false) {
                                canvasBackgroundSwatch(
                                    color: canvasBackground,
                                    isSelected: false,
                                    showsEyedropper: true
                                )
                            }
                            .onChange(of: canvasBackground) { _, _ in
                                appStore.showToast(L10n.backgroundColorApplied)
                            }
                            .accessibilityLabel(L10n.customColor)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                    .scrollClipDisabled(false)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

                    Button(L10n.resetBackgroundColor) {
                        applyCanvasBackground(CanvasMediumDefaults.canvasBackground)
                    }
                }

                if activeMedium != nil {
                    Button(L10n.resetMedium) {
                        resetMediumSettings()
                        showStageSheet = false
                    }
                }

                Button(L10n.saveDraft) {
                    saveArtwork(isDraft: true)
                    showStageSheet = false
                }
                .disabled(viewModel.paths.isEmpty && viewModel.backgroundImage == nil)

                if viewModel.backgroundImage != nil {
                    Button(L10n.removeBackground, role: .destructive) {
                        viewModel.backgroundImage = nil
                        showStageSheet = false
                        appStore.showToast(L10n.removeBackground)
                    }
                }

                Button(L10n.clearCanvas, role: .destructive) {
                    clearCanvas()
                    showStageSheet = false
                }
                .disabled(!canClearCanvas)
            }
            .navigationTitle(L10n.canvasSettings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) { showStageSheet = false }
                }
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func applyCanvasBackground(_ color: Color) {
        canvasBackground = color
        CanvasHaptics.light()
        appStore.showToast(L10n.backgroundColorApplied)
    }

    private func canvasBackgroundSwatch(
        color: Color,
        isSelected: Bool,
        showsEyedropper: Bool = false
    ) -> some View {
        MSColorSwatch(
            color: color,
            isSelected: isSelected,
            size: 36,
            showsCheckmark: !showsEyedropper,
            showsEyedropper: showsEyedropper
        )
    }

    private func colorsMatch(_ a: Color, _ b: Color) -> Bool {
        MSColorMatch.matches(a, b)
    }

    private var layersSheet: some View {
        NavigationStack {
            List {
                Section(L10n.layersTitle) {
                    Label(L10n.layersCount(viewModel.paths.count), systemImage: "square.stack.3d.up")

                    if viewModel.paths.isEmpty {
                        Text(L10n.canvasReady)
                            .foregroundStyle(MSColor.onSurfaceVariant)
                    } else {
                        ForEach(Array(viewModel.paths.enumerated().reversed()), id: \.element.id) { index, path in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(path.isEraser ? MSColor.outlineVariant : path.color)
                                    .frame(width: 14, height: 14)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(path.isEraser ? L10n.eraserLayer : L10n.strokeLayer(index + 1))
                                        .font(.system(size: 15, weight: .medium))
                                    Text(L10n.strokeSize(Int(path.lineWidth)))
                                        .font(.caption)
                                        .foregroundStyle(MSColor.onSurfaceVariant)
                                }
                                Spacer()
                                Button {
                                    deleteStroke(withID: path.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.opacity(0.85))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if canClearCanvas {
                    Section {
                        Button(L10n.clearCanvas, role: .destructive) {
                            clearCanvas()
                            showLayersSheet = false
                        }
                    }
                }
            }
            .navigationTitle(L10n.layers)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) {
                        showLayersSheet = false
                        if selectedTool == .layers {
                            selectedTool = .brush
                        }
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func toolButton(_ tool: DrawingTool) -> some View {
        Button {
            selectedTool = tool
        } label: {
            Image(systemName: tool.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(selectedTool == tool ? MSColor.primary : MSColor.onSurfaceVariant)
                .frame(width: 40, height: 36)
                .background {
                    if selectedTool == tool {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MSColor.primaryContainer.opacity(0.55))
                    }
                }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(tool.label)
    }

    private func secondaryTool(icon: String, label: String) -> some View {
        Image(systemName: icon)
            .font(.body.weight(.semibold))
            .foregroundStyle(MSColor.onSurfaceVariant)
            .frame(width: 40, height: 36)
            .accessibilityLabel(label)
    }

    private func undo() {
        viewModel.undo()
    }

    private func redo() {
        viewModel.redo()
    }

    private func deleteStroke(withID id: UUID) {
        viewModel.deleteStroke(withID: id)
    }

    private func clearCanvas() {
        guard canClearCanvas else { return }
        viewModel.clearCanvas(clearBackground: appStore.editingArtworkID == nil)
        resetCanvasView()
        CanvasHaptics.medium()
        appStore.showToast(L10n.canvasCleared)
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        viewModel.loadPhoto(from: item, appStore: appStore)
    }

    private func saveArtwork(isDraft: Bool) {
        viewModel.saveArtwork(
            appStore: appStore,
            canvasBackground: canvasBackground,
            isDraft: isDraft
        ) {
            selectedTab?.wrappedValue = .studio
        }
    }
}

#Preview {
    DrawingCanvasView()
        .environment(AppStore())
}
