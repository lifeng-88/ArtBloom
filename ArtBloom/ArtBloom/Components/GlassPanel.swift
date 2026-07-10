import SwiftUI

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = MSSpacing.cardRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(MSColor.blush.opacity(0.18))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        MSColor.glassBorder.opacity(0.65),
                                        MSColor.blush.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
    }
}

struct GlassTopBar: View {
    var title: String
    var icon: String
    var trailing: AnyView?

    init(title: String, icon: String = "paintpalette.fill", @ViewBuilder trailing: () -> some View = { EmptyView() }) {
        self.title = title
        self.icon = icon
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(MSGradient.primary)
                MSTypography.displayMobile(title)
                    .foregroundStyle(MSColor.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)
            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, MSSpacing.containerPadding)
        .frame(height: MSLayout.topBarHeight)
        .background {
            MSColor.roseMist.opacity(0.72)
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MSColor.blush.opacity(0.25))
                .frame(height: 1)
        }
    }
}

struct PillButton: View {
    let title: String
    var icon: String?
    var style: Style = .primary
    var fullWidth: Bool = false
    var action: () -> Void = {}

    enum Style {
        case primary, ghost, glass
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                MSTypography.label(title)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(background)
        }
        .buttonStyle(PressScaleStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return MSColor.onPrimary
        case .ghost: return MSColor.primary
        case .glass: return MSColor.glassFill
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Capsule().fill(MSGradient.primary)
            .shadow(color: MSColor.primary.opacity(0.25), radius: 10, y: 4)
        case .ghost:
            Capsule().strokeBorder(MSColor.primary.opacity(0.4), lineWidth: 1.5)
        case .glass:
            Capsule()
                .fill(MSColor.blush.opacity(0.22))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(MSColor.glassBorder.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

struct MSEmptyState: View {
    let icon: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(MSColor.blush.opacity(0.2))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(MSGradient.primary)
                    .symbolRenderingMode(.hierarchical)
            }

            MSTypography.body(message)
                .foregroundStyle(MSColor.onSurfaceVariant)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                PillButton(title: actionTitle, style: .primary, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

struct FavoriteToggleButton: View {
    let isFavorite: Bool
    var onDarkBackground: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isFavorite ? MSColor.primary : (onDarkBackground ? .white : MSColor.onSurfaceVariant))
                .padding(7)
                .background {
                    if onDarkBackground {
                        Circle().fill(.ultraThinMaterial)
                    }
                }
                .symbolEffect(.bounce, value: isFavorite)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct AvatarView: View {
    let url: String
    var size: CGFloat = 32

    var body: some View {
        RemoteImage(url: url, targetSize: CGSize(width: size, height: size))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(MSColor.primaryContainer.opacity(0.8), lineWidth: 2))
            .shadow(color: MSColor.primary.opacity(0.12), radius: 6, y: 2)
    }
}

struct ProfileAvatarView: View {
    @Environment(AppStore.self) private var appStore
    var size: CGFloat = 32
    var fallbackURL: String = SampleData.avatarURL

    var body: some View {
        Group {
            if let url = appStore.profileAvatarFileURL {
                LocalArtworkImage(url: url, targetSize: CGSize(width: size, height: size))
            } else {
                RemoteImage(url: fallbackURL, targetSize: CGSize(width: size, height: size))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(MSColor.primaryContainer.opacity(0.8), lineWidth: 2))
        .shadow(color: MSColor.primary.opacity(0.12), radius: 6, y: 2)
    }
}

struct MSShimmer: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    MSColor.surfaceContainerHigh.opacity(0.4),
                    MSColor.surfaceContainer.opacity(0.9),
                    MSColor.surfaceContainerHigh.opacity(0.4)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 1.5)
            .offset(x: phase * geo.size.width)
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
        }
        .clipped()
    }
}
