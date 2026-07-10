import SwiftUI
import UIKit

struct CanvasExportView: View {
    let paths: [DrawingPath]
    let backgroundImage: UIImage?
    let canvasBackground: Color
    let size: CGSize

    var body: some View {
        ZStack {
            canvasBackground
            if let backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            PathsCanvas(paths: paths, currentPath: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
    }
}

enum CanvasExportService {
    @MainActor
    static func render(
        paths: [DrawingPath],
        backgroundImage: UIImage?,
        canvasBackground: Color,
        size: CGSize
    ) -> UIImage? {
        let exportView = CanvasExportView(
            paths: paths,
            backgroundImage: backgroundImage,
            canvasBackground: canvasBackground,
            size: size
        )
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
