import PhotosUI
import SwiftUI
import UIKit

enum PhotoImportHelper {
    private static let maxImportPixelSize: CGFloat = 2048

    static func loadImage(from item: PhotosPickerItem?) async -> UIImage? {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        let scale = await MainActor.run { UIScreen.main.scale }
        let maxPointSize = maxImportPixelSize / scale
        let targetSize = CGSize(width: maxPointSize, height: maxPointSize)
        return await Task.detached(priority: .userInitiated) {
            ImageDownsampler.decode(data: data, targetSize: targetSize, scale: scale)
        }.value
    }

    static func loadImage(from item: PhotosPickerItem?, onResult: @escaping @MainActor (UIImage?) -> Void) {
        Task {
            let image = await loadImage(from: item)
            await MainActor.run {
                onResult(image)
            }
        }
    }
}
