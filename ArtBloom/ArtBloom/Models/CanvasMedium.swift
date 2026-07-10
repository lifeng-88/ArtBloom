import SwiftUI

enum MediumKind: String, Equatable {
    case oilPainting
    case watercolor
    case sketch
    case digitalArt
    case vintageBloom
    case modernChic
    case dreamyPastel
    case streetStyle
    case inspiration
}

struct CanvasMediumSelection: Equatable {
    let name: String
    let kind: MediumKind
    var imageURL: String?

    var localizedName: String {
        let resolvedImageURL = imageURL ?? SampleData.previewImageURL(for: kind)
        if let match = SampleData.mediums.first(where: { $0.kind == kind && $0.imageURL == resolvedImageURL }) {
            return match.name
        }
        if let match = SampleData.styleTemplates().first(where: { $0.kind == kind && $0.imageURL == resolvedImageURL }) {
            return match.name
        }
        if let match = SampleData.profileArtworks.first(where: { $0.mediumKind == kind && $0.imageURL == resolvedImageURL }) {
            return match.title
        }
        return kind.displayName
    }

    func previewItem() -> MediumItem {
        MediumItem(
            name: localizedName,
            kind: kind,
            imageURL: imageURL ?? SampleData.previewImageURL(for: kind)
        )
    }
}

extension MediumKind {
    var displayName: String {
        switch self {
        case .oilPainting: return L10n.mediumOilPainting
        case .watercolor: return L10n.mediumWatercolor
        case .sketch: return L10n.mediumSketch
        case .digitalArt: return L10n.mediumDigitalArt
        case .vintageBloom: return L10n.templateVintageBloom
        case .modernChic: return L10n.templateModernChic
        case .dreamyPastel: return L10n.templateDreamyPastel
        case .streetStyle: return L10n.templateStreetStyle
        case .inspiration: return L10n.sampleInspiration
        }
    }
}

struct CanvasMediumPreset {
    let kind: MediumKind
    let strokeWidth: Double
    let strokeOpacity: Double
    let eraserScale: Double
    let colors: [Color]
    let canvasBackground: Color
    let strokeRange: ClosedRange<Double>

    var description: String {
        switch kind {
        case .oilPainting: return L10n.mediumDescOilPainting
        case .watercolor: return L10n.mediumDescWatercolor
        case .sketch: return L10n.mediumDescSketch
        case .digitalArt: return L10n.mediumDescDigitalArt
        case .vintageBloom: return L10n.mediumDescVintageBloom
        case .modernChic: return L10n.mediumDescModernChic
        case .dreamyPastel: return L10n.mediumDescDreamyPastel
        case .streetStyle: return L10n.mediumDescStreetStyle
        case .inspiration: return L10n.mediumDescInspiration
        }
    }

    static func forKind(_ kind: MediumKind) -> CanvasMediumPreset {
        switch kind {
        case .oilPainting:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 14,
                strokeOpacity: 1,
                eraserScale: 3,
                colors: [
                    Color(hex: "5C4033"),
                    Color(hex: "8B3A3A"),
                    Color(hex: "C9A227"),
                    Color(hex: "F5E6D3"),
                    Color(hex: "3D2B1F")
                ],
                canvasBackground: MSColor.canvasPaper(light: "FFF8F0"),
                strokeRange: 6...40
            )
        case .watercolor:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 8,
                strokeOpacity: 0.42,
                eraserScale: 2,
                colors: [
                    MSColor.blush.opacity(0.9),
                    MSColor.lavender,
                    MSColor.softBlue,
                    MSColor.cream,
                    Color(hex: "7EBDC2")
                ],
                canvasBackground: MSColor.canvasPaper(light: "F0F8FF"),
                strokeRange: 2...24
            )
        case .sketch:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 2,
                strokeOpacity: 0.88,
                eraserScale: 1.8,
                colors: [
                    Color(hex: "1A1A1A"),
                    Color(hex: "333333"),
                    Color(hex: "666666"),
                    Color(hex: "999999"),
                    Color(hex: "CCCCCC")
                ],
                canvasBackground: MSColor.canvasPaper(light: "FAFAFA", dark: "161C24"),
                strokeRange: 1...8
            )
        case .digitalArt:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 4,
                strokeOpacity: 1,
                eraserScale: 2.5,
                colors: [
                    MSColor.blush,
                    MSColor.lavender,
                    MSColor.cream,
                    MSColor.softBlue,
                    MSColor.primary
                ],
                canvasBackground: MSColor.surfaceContainerLowest,
                strokeRange: 1...40
            )
        case .vintageBloom:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 6,
                strokeOpacity: 0.72,
                eraserScale: 2.2,
                colors: [
                    Color(hex: "8B6914"),
                    Color(hex: "C08081"),
                    Color(hex: "9CAF88"),
                    Color(hex: "E8C4A0"),
                    Color(hex: "6B4423")
                ],
                canvasBackground: MSColor.canvasPaper(light: "FFF5EE"),
                strokeRange: 2...20
            )
        case .modernChic:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 5,
                strokeOpacity: 1,
                eraserScale: 2.5,
                colors: [
                    Color(hex: "1A1A1A"),
                    Color.white,
                    MSColor.primary,
                    Color(hex: "888888"),
                    Color(hex: "E53935")
                ],
                canvasBackground: MSColor.canvasPaper(light: "F5F5F5", dark: "1A1F28"),
                strokeRange: 1...30
            )
        case .dreamyPastel:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 10,
                strokeOpacity: 0.38,
                eraserScale: 2,
                colors: [
                    Color(hex: "FFB7C5"),
                    Color(hex: "E6E6FA"),
                    Color(hex: "B5EAD7"),
                    Color(hex: "FFDAB9"),
                    Color(hex: "B0E0E6")
                ],
                canvasBackground: MSColor.canvasPaper(light: "FFF0F5"),
                strokeRange: 4...28
            )
        case .streetStyle:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 5,
                strokeOpacity: 0.88,
                eraserScale: 2.3,
                colors: [
                    Color(hex: "1C1C1C"),
                    Color(hex: "6B8EAE"),
                    Color(hex: "D4A574"),
                    Color(hex: "F5F0EB"),
                    Color(hex: "8B7355")
                ],
                canvasBackground: MSColor.canvasPaper(light: "FAF7F4"),
                strokeRange: 2...22
            )
        case .inspiration:
            return CanvasMediumPreset(
                kind: kind,
                strokeWidth: 6,
                strokeOpacity: 0.55,
                eraserScale: 2.2,
                colors: [
                    Color(hex: "FF9A76"),
                    Color(hex: "FFD4B8"),
                    Color(hex: "C9B1FF"),
                    Color(hex: "FFE066"),
                    Color(hex: "87CEEB")
                ],
                canvasBackground: MSColor.canvasPaper(light: "FFF8F0"),
                strokeRange: 2...24
            )
        }
    }
}

enum CanvasBackgroundPresets {
    static let options: [Color] = [
        MSColor.surfaceContainerLowest,
        MSColor.cream,
        MSColor.softBlue,
        MSColor.lavender,
        MSColor.canvasPaper(light: "1A1A1A", dark: "0A0F14")
    ]
}

enum CanvasMediumDefaults {
    static let strokeWidth: Double = 4
    static let strokeOpacity: Double = 1
    static let eraserScale: Double = 2.5
    static let canvasBackground = MSColor.surfaceContainerLowest
    static let strokeRange: ClosedRange<Double> = 1...40

    static var palette: [Color] {
        [MSColor.blush, MSColor.lavender, MSColor.cream, MSColor.softBlue, MSColor.primary]
    }
}
