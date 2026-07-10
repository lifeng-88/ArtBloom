import PhotosUI
import SwiftUI
import UIKit

@Observable
@MainActor
final class CanvasViewModel {
    var paths: [DrawingPath] = []
    var currentPath: DrawingPath?
    var redoStack: [DrawingPath] = []
    var backgroundImage: UIImage?
    var canvasSize: CGSize = .zero
    var pendingSessionRestore: ArtworkSession?
    var isSaving = false

    var hasContent: Bool {
        !paths.isEmpty || backgroundImage != nil
    }

    func undo() {
        guard let last = paths.popLast() else { return }
        redoStack.append(last)
        CanvasHaptics.medium()
    }

    func redo() {
        guard let last = redoStack.popLast() else { return }
        paths.append(last)
        CanvasHaptics.medium()
    }

    func deleteStroke(withID id: UUID) {
        guard let index = paths.firstIndex(where: { $0.id == id }) else { return }
        paths.remove(at: index)
        redoStack.removeAll()
        CanvasHaptics.light()
    }

    func clearCanvas(clearBackground: Bool) {
        paths.removeAll()
        redoStack.removeAll()
        currentPath = nil
        if clearBackground {
            backgroundImage = nil
        }
    }

    func restorePendingSessionIfNeeded() {
        guard canvasSize.width > 1, canvasSize.height > 1,
              let session = pendingSessionRestore else { return }
        let reference = session.canvasSize
        paths = session.paths.map { $0.toDrawingPath(canvasSize: canvasSize, referenceSize: reference) }
        pendingSessionRestore = nil
    }

    func applyPendingBackground(from appStore: AppStore) -> Bool {
        guard let image = appStore.pendingCanvasBackground else { return false }
        backgroundImage = image
        appStore.pendingCanvasBackground = nil
        appStore.showToast(L10n.photoImported)
        return true
    }

    func loadEditingSession(appStore: AppStore) async -> Color? {
        guard let editID = appStore.editingArtworkID,
              let artwork = appStore.artworkStore.artwork(with: editID) else { return nil }

        paths.removeAll()
        redoStack.removeAll()
        currentPath = nil

        var restoredBackground: Color?
        if let session = appStore.artworkStore.loadSession(for: editID) {
            pendingSessionRestore = session
            if let hex = session.canvasBackgroundHex {
                restoredBackground = Color(hex: hex)
            }
            restorePendingSessionIfNeeded()
            let baseURL = appStore.artworkStore.baseImageURL(for: artwork)
            backgroundImage = await ImageCache.shared.loadLocal(from: baseURL, targetSize: nil)
            return restoredBackground
        }

        let url = appStore.artworkStore.imageURL(for: artwork)
        backgroundImage = await ImageCache.shared.loadLocal(from: url, targetSize: nil)
        return restoredBackground
    }

    func loadPhoto(from item: PhotosPickerItem?, appStore: AppStore) {
        PhotoImportHelper.loadImage(from: item) { [weak self] image in
            Task { @MainActor in
                guard let self else { return }
                if let image {
                    self.backgroundImage = image
                    appStore.showToast(L10n.photoImported)
                } else if item != nil {
                    appStore.showToast(L10n.photoLoadFailed, style: .error)
                }
            }
        }
    }

    func saveArtwork(
        appStore: AppStore,
        canvasBackground: Color,
        isDraft: Bool,
        navigateToStudio: () -> Void
    ) {
        guard !isSaving else { return }
        isSaving = true

        let size = canvasSize == .zero ? CGSize(width: 320, height: 400) : canvasSize
        let session = ArtworkSession(
            paths: paths.map { StoredDrawingPath(from: $0, canvasSize: size) },
            canvasBackgroundHex: canvasBackground.hexString,
            canvasWidth: Double(size.width),
            canvasHeight: Double(size.height)
        )

        guard let previewImage = CanvasExportService.render(
            paths: paths,
            backgroundImage: backgroundImage,
            canvasBackground: canvasBackground,
            size: size
        ), let baseImage = CanvasExportService.render(
            paths: [],
            backgroundImage: backgroundImage,
            canvasBackground: canvasBackground,
            size: size
        ) else {
            appStore.showToast(L10n.saveFailed, style: .error)
            isSaving = false
            return
        }

        if let editID = appStore.editingArtworkID {
            if appStore.artworkStore.updateArtwork(
                id: editID,
                previewImage: previewImage,
                baseImage: baseImage,
                session: session
            ) {
                if !isDraft {
                    appStore.artworkStore.promoteDraft(editID)
                }
                appStore.showToast(L10n.updatedSuccess)
                appStore.clearEditingSession()
                if !isDraft {
                    navigateToStudio()
                }
            } else {
                appStore.showToast(L10n.saveFailed, style: .error)
            }
        } else {
            let index = appStore.artworkStore.items.count + 1
            let title = L10n.untitledArtwork(index)
            let subtitle = isDraft ? L10n.formatDate(Date()) : L10n.artworkDigitalPainting
            let payload = ArtworkSavePayload(
                previewImage: previewImage,
                baseImage: baseImage,
                session: session,
                title: title,
                subtitle: subtitle,
                isDraft: isDraft
            )
            if appStore.artworkStore.save(payload) {
                appStore.showToast(isDraft ? L10n.saveDraftSuccess : L10n.saveSuccess)
                if !isDraft {
                    navigateToStudio()
                }
            } else {
                appStore.showToast(L10n.saveFailed, style: .error)
            }
        }

        isSaving = false
    }
}
