import SwiftUI
import UIKit

enum MSColor {
  private static func adaptive(light: String, dark: String) -> Color {
    Color(uiColor: UIColor { trait in
      UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
    })
  }

  static let primary = adaptive(light: "7B5455", dark: "D4A5A6")
  static let primaryLight = adaptive(light: "9B7475", dark: "E0B8B9")
  static let onPrimary = Color.white
  static let primaryContainer = adaptive(light: "F4C2C2", dark: "4A3233")
  static let onPrimaryContainer = adaptive(light: "734E4E", dark: "F4C2C2")
  static let error = adaptive(light: "C62828", dark: "EF9A9A")
  static let glassBorder = adaptive(light: "FFFFFF", dark: "F4C2C2")
  static let glassFill = adaptive(light: "FFF8FA", dark: "2A1E22")

  static let secondary = adaptive(light: "8C6A6B", dark: "C9A0A1")
  static let secondaryContainer = adaptive(light: "F5E6EA", dark: "2E2226")
  static let onSecondaryContainer = adaptive(light: "6B4F50", dark: "E8D4D6")

  static let tertiary = adaptive(light: "9A7B7C", dark: "B8A0A1")
  static let tertiaryContainer = adaptive(light: "FCEEF2", dark: "322428")

  static let background = adaptive(light: "F5FAFF", dark: "100D10")
  static let onBackground = adaptive(light: "3D2A2C", dark: "F5E8EA")
  static let onSurface = adaptive(light: "3D2A2C", dark: "F5E8EA")
  static let onSurfaceVariant = adaptive(light: "6B5254", dark: "B8A4A6")

  static let surface = adaptive(light: "F5FAFF", dark: "100D10")
  static let surfaceContainerLow = adaptive(light: "FFF5F8", dark: "1A1418")
  static let surfaceContainer = adaptive(light: "FAE8EE", dark: "22181C")
  static let surfaceContainerHigh = adaptive(light: "F5DDE5", dark: "2A1E22")
  static let surfaceContainerHighest = adaptive(light: "EFD5DE", dark: "322428")
  static let surfaceContainerLowest = adaptive(light: "FFFFFF", dark: "0C090B")

  static let outline = adaptive(light: "9A7B7C", dark: "A88889")
  static let outlineVariant = adaptive(light: "E8D0D4", dark: "4A383A")

  static let lavender = adaptive(light: "F5E6FA", dark: "2A2430")
  static let cream = adaptive(light: "FFF5F0", dark: "3A3028")
  static let softBlue = adaptive(light: "E8F0FA", dark: "243038")
  static let blush = adaptive(light: "F4C2C2", dark: "5C3D3E")
  static let softRose = adaptive(light: "FFD6E0", dark: "4A3238")
  static let roseMist = adaptive(light: "FFF0F5", dark: "241A1E")

  static let swatchBorder = adaptive(light: "FFFFFF", dark: "F4C2C2")

  static func canvasPaper(light: String, dark: String = "1E2A38") -> Color {
    adaptive(light: light, dark: dark)
  }
}

enum MSGradient {
    static func brandBackground(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "100D10"), Color(hex: "1A1218"), Color(hex: "18101A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(hex: "F5FAFF"), Color(hex: "FFF5F8"), Color(hex: "FCEEF2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let primary = LinearGradient(
        colors: [Color(hex: "7B5455"), Color(hex: "9B7475"), Color(hex: "B88B8C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroOverlay = LinearGradient(
        colors: [
            Color(hex: "3D2A2C").opacity(0.82),
            Color(hex: "7B5455").opacity(0.35),
            .clear
        ],
        startPoint: .bottom,
        endPoint: .top
    )
}

struct MSBrandBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            MSGradient.brandBackground(colorScheme)

            Circle()
                .fill(MSColor.blush.opacity(colorScheme == .dark ? 0.12 : 0.28))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -140, y: -220)

            Circle()
                .fill(MSColor.softRose.opacity(colorScheme == .dark ? 0.08 : 0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 150, y: 320)
        }
        .ignoresSafeArea()
    }
}

enum MSShadow {
    static func card(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? MSColor.primary.opacity(0.2) : MSColor.primary.opacity(0.08)
    }

    static let cardRadius: CGFloat = 12
    static let elevatedRadius: CGFloat = 16
}

enum MSSectionSpacing {
    static let tight: CGFloat = 24
    static let standard: CGFloat = 32
    static let loose: CGFloat = 40
}

enum MSTypography {
    static func displayMobile(_ text: String) -> some View {
        Text(text)
            .font(.system(.title, design: .serif).weight(.bold))
            .tracking(-0.5)
            .padding(.leading, 1)
    }

    static func headline(_ text: String) -> some View {
        Text(text)
            .font(.system(.title2, design: .serif).weight(.semibold))
    }

    static func bodyLarge(_ text: String) -> some View {
        Text(text)
            .font(.body)
    }

    static func body(_ text: String) -> some View {
        Text(text)
            .font(.callout)
    }

    static func label(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .tracking(L10n.usesCJKTypography ? 0 : 0.6)
    }

    static func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .serif).weight(.semibold))
    }

    static func toolbarTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .serif).weight(.bold))
    }
}

enum MSSpacing {
    static let containerPadding: CGFloat = 20
    static let gutter: CGFloat = 16
    static let canvasMargin: CGFloat = 24
    static let unit: CGFloat = 8
    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 16
}

enum MSLayout {
    static let tabBarHeight: CGFloat = 80
    static let topBarHeight: CGFloat = 64
    static let scrollBottomInset: CGFloat = 24
    static let tabContentBottomInset: CGFloat = tabBarHeight + scrollBottomInset
    static let fabBottomInset: CGFloat = 16
}

/// Prevents nested horizontal ScrollViews from expanding vertical ScrollView content width beyond the screen.
struct MSScrollContentWidth: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerRelativeFrame(.horizontal)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct MSPageScroll: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}

extension View {
    func msScrollContentWidth() -> some View {
        modifier(MSScrollContentWidth())
    }

    func msPageScroll() -> some View {
        modifier(MSPageScroll())
    }

    func msBrandBackground() -> some View {
        background(MSBrandBackground())
    }

    func msCardShadow(_ colorScheme: ColorScheme, radius: CGFloat = MSShadow.cardRadius) -> some View {
        shadow(color: MSShadow.card(colorScheme), radius: radius, y: 4)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
