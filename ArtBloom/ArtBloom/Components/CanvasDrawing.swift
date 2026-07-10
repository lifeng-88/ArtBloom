import SwiftUI
import UIKit

struct DrawingPath: Identifiable, Equatable {
    let id: UUID
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var opacity: Double
    var isEraser: Bool

    init(
        id: UUID = UUID(),
        points: [CGPoint],
        color: Color,
        lineWidth: CGFloat,
        opacity: Double,
        isEraser: Bool
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.isEraser = isEraser
    }
}

struct StoredDrawingPath: Codable, Equatable {
    let id: UUID
    var points: [CGPoint]
    var colorHex: String
    var lineWidth: CGFloat
    var opacity: Double
    var isEraser: Bool

    init(from path: DrawingPath, canvasSize: CGSize = .zero) {
        id = path.id
        colorHex = path.color.hexString ?? "7B5455"
        opacity = path.opacity
        isEraser = path.isEraser

        if canvasSize.width > 1, canvasSize.height > 1 {
            points = path.points.map {
                CGPoint(x: $0.x / canvasSize.width, y: $0.y / canvasSize.height)
            }
            lineWidth = path.lineWidth / canvasSize.width
        } else {
            points = path.points
            lineWidth = path.lineWidth
        }
    }

    func toDrawingPath(canvasSize: CGSize = .zero, referenceSize: CGSize? = nil) -> DrawingPath {
        let restoredPoints: [CGPoint]
        let restoredWidth: CGFloat

        if let referenceSize, referenceSize.width > 1, referenceSize.height > 1, canvasSize.width > 1, canvasSize.height > 1 {
            restoredPoints = points.map {
                CGPoint(x: $0.x * canvasSize.width, y: $0.y * canvasSize.height)
            }
            restoredWidth = lineWidth * canvasSize.width / referenceSize.width
        } else {
            restoredPoints = points
            restoredWidth = lineWidth
        }

        return DrawingPath(
            id: id,
            points: restoredPoints,
            color: Color(hex: colorHex),
            lineWidth: restoredWidth,
            opacity: opacity,
            isEraser: isEraser
        )
    }
}

struct ArtworkSession: Codable, Equatable {
    var paths: [StoredDrawingPath]
    var canvasBackgroundHex: String?
    var canvasWidth: Double?
    var canvasHeight: Double?

    var canvasSize: CGSize? {
        guard let canvasWidth, let canvasHeight, canvasWidth > 1, canvasHeight > 1 else { return nil }
        return CGSize(width: canvasWidth, height: canvasHeight)
    }
}

enum CanvasHaptics {
    static var isEnabled = true

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)

    static func light() {
        guard isEnabled else { return }
        lightGenerator.prepare()
        lightGenerator.impactOccurred()
    }

    static func medium() {
        guard isEnabled else { return }
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
    }
}

enum CanvasStrokeRenderer {
    static func path(from points: [CGPoint]) -> Path {
        guard !points.isEmpty else { return Path() }

        if points.count == 1 {
            let pt = points[0]
            return Path(ellipseIn: CGRect(x: pt.x - 0.5, y: pt.y - 0.5, width: 1, height: 1))
        }

        var result = Path()
        result.move(to: points[0])

        if points.count == 2 {
            result.addLine(to: points[1])
            return result
        }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            if index == 1 {
                result.addLine(to: midpoint)
            } else {
                result.addQuadCurve(to: midpoint, control: previous)
            }
        }

        if let last = points.last {
            result.addLine(to: last)
        }
        return result
    }

    static func draw(_ stroke: DrawingPath, in context: inout GraphicsContext, asFill: Bool = false, eraser: Bool = false) {
        guard !stroke.points.isEmpty else { return }

        let paintColor: Color = eraser
            ? .white
            : stroke.color.opacity(stroke.opacity)

        if stroke.points.count == 1 || asFill {
            let radius = stroke.lineWidth / 2
            let pt = stroke.points[0]
            let rect = CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(paintColor))
            return
        }

        let shape = path(from: stroke.points)
        context.stroke(
            shape,
            with: .color(paintColor),
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private static func renderStroke(_ stroke: DrawingPath, in context: inout GraphicsContext) {
        if stroke.isEraser {
            context.blendMode = .destinationOut
            draw(stroke, in: &context, eraser: true)
            context.blendMode = .normal
        } else {
            draw(stroke, in: &context)
        }
    }

    static func render(paths: [DrawingPath], currentPath: DrawingPath?, in context: inout GraphicsContext) {
        context.drawLayer { layer in
            for stroke in paths {
                renderStroke(stroke, in: &layer)
            }
            if let currentPath {
                renderStroke(currentPath, in: &layer)
            }
        }
    }
}

struct PathsCanvas: View {
    let paths: [DrawingPath]
    let currentPath: DrawingPath?

    var body: some View {
        Canvas { context, _ in
            CanvasStrokeRenderer.render(paths: paths, currentPath: currentPath, in: &context)
        }
    }
}

struct CanvasGridPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            let dotColor = MSColor.primary.opacity(0.03)
            var dots = Path()
            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    dots.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
            context.fill(dots, with: .color(dotColor))
        }
    }
}
