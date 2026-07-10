import SwiftUI

enum MSColorMatch {
    static func isDark(_ color: Color) -> Bool {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) < 0.55
    }

    static func matches(_ a: Color, _ b: Color) -> Bool {
        let uiA = UIColor(a)
        let uiB = UIColor(b)
        var rA: CGFloat = 0, gA: CGFloat = 0, bA: CGFloat = 0, aA: CGFloat = 0
        var rB: CGFloat = 0, gB: CGFloat = 0, bB: CGFloat = 0, aB: CGFloat = 0
        uiA.getRed(&rA, green: &gA, blue: &bA, alpha: &aA)
        uiB.getRed(&rB, green: &gB, blue: &bB, alpha: &aB)
        let threshold: CGFloat = 0.01
        return abs(rA - rB) < threshold && abs(gA - gB) < threshold
            && abs(bA - bB) < threshold && abs(aA - aB) < threshold
    }
}

struct MSColorSwatch: View {
    let color: Color
    var isSelected: Bool = false
    var size: CGFloat = 28
    var showsCheckmark: Bool = true
    var showsEyedropper: Bool = false

    private var isDark: Bool { MSColorMatch.isDark(color) }
    private var ringDiameter: CGFloat { size + 10 }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(MSColor.primaryContainer.opacity(0.5))
                    .frame(width: ringDiameter + 6, height: ringDiameter + 6)
                    .blur(radius: 3)
            }

            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.3 : 0.9),
                                    Color.black.opacity(isDark ? 0.18 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 2 : 1.5
                        )
                }
                .shadow(
                    color: Color.black.opacity(isSelected ? 0.14 : 0.08),
                    radius: isSelected ? 4 : 2,
                    y: isSelected ? 2 : 1
                )

            if showsEyedropper {
                Image(systemName: "eyedropper.halffull")
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(isDark ? .white : MSColor.onSurfaceVariant)
            }

            if isSelected {
                Circle()
                    .strokeBorder(MSGradient.primary, lineWidth: 2.5)
                    .frame(width: ringDiameter, height: ringDiameter)

                Circle()
                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                    .frame(width: ringDiameter - 4, height: ringDiameter - 4)

                if showsCheckmark && !showsEyedropper {
                    Image(systemName: "checkmark")
                        .font(.system(size: max(9, size * 0.34), weight: .heavy))
                        .foregroundStyle(isDark ? Color.white : MSColor.primary)
                        .shadow(color: Color.black.opacity(isDark ? 0.35 : 0), radius: 1, y: 0.5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: ringDiameter + 6, height: ringDiameter + 6)
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.spring(response: 0.34, dampingFraction: 0.62), value: isSelected)
    }
}

struct MSCustomColorPickerButton: View {
    @Binding var selection: Color
    var isSelected: Bool
    var size: CGFloat = 28
    var accessibilityLabel: String

    private var ringDiameter: CGFloat { size + 12 }

    private var spectrumGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(hex: "FF6B6B"),
                Color(hex: "FFE66D"),
                Color(hex: "6BCB77"),
                Color(hex: "4D96FF"),
                Color(hex: "C77DFF"),
                Color(hex: "FF6B6B")
            ]),
            center: .center
        )
    }

    var body: some View {
        ColorPicker(selection: $selection, supportsOpacity: false) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(MSColor.primaryContainer.opacity(0.45))
                        .frame(width: ringDiameter + 6, height: ringDiameter + 6)
                        .blur(radius: 3)
                }

                Circle()
                    .strokeBorder(spectrumGradient, lineWidth: isSelected ? 3 : 2.5)
                    .frame(width: size + 8, height: size + 8)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MSColor.surfaceContainerLow, MSColor.surfaceContainer],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: size * 0.42, weight: .semibold))
                            .foregroundStyle(MSGradient.primary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)

                if isSelected {
                    Circle()
                        .fill(selection)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        .offset(x: size * 0.28, y: size * 0.28)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: ringDiameter + 6, height: ringDiameter + 6)
            .scaleEffect(isSelected ? 1.08 : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.62), value: isSelected)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}
