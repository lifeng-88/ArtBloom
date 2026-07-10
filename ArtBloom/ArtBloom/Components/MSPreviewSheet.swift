import SwiftUI

struct MSPreviewSheetLayout<Hero: View, Content: View, Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    @ViewBuilder var hero: () -> Hero
    @ViewBuilder var content: () -> Content
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        primaryTitle: String? = nil,
        primaryAction: (() -> Void)? = nil,
        @ViewBuilder hero: @escaping () -> Hero,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.hero = hero
        self.content = content
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    hero()
                    content()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, primaryAction == nil ? 20 : 8)
            }
        }
        .msBrandBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let primaryTitle, let primaryAction {
                bottomActionBar(title: primaryTitle, action: primaryAction)
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            MSTypography.headline(title)
                .foregroundStyle(MSColor.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            trailing()

            Button {
                dismiss()
            } label: {
                Text(L10n.done)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MSColor.onPrimaryContainer)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(MSColor.primaryContainer.opacity(0.65)))
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background {
            MSColor.roseMist.opacity(0.55)
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MSColor.blush.opacity(0.2))
                .frame(height: 1)
        }
    }

    private func bottomActionBar(title: String, action: @escaping () -> Void) -> some View {
        PillButton(title: title, style: .primary, fullWidth: true, action: action)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background {
                MSColor.roseMist.opacity(0.88)
                    .background(.ultraThinMaterial)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(MSColor.blush.opacity(0.2))
                    .frame(height: 1)
            }
    }
}

extension MSPreviewSheetLayout where Trailing == EmptyView {
    init(
        title: String,
        primaryTitle: String? = nil,
        primaryAction: (() -> Void)? = nil,
        @ViewBuilder hero: @escaping () -> Hero,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            primaryTitle: primaryTitle,
            primaryAction: primaryAction,
            hero: hero,
            content: content,
            trailing: { EmptyView() }
        )
    }
}

struct MSPreviewHeroImage: View {
    let url: String
    var aspectRatio: CGFloat = 4 / 5

    var body: some View {
        SizedRemoteImage(url: url, contentMode: .fill)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(MSColor.glassBorder.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: MSColor.primary.opacity(0.1), radius: 16, y: 6)
    }
}

struct MSPreviewInfoCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        GlassPanel(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 6) {
                MSTypography.headline(title)
                    .foregroundStyle(MSColor.primary)
                MSTypography.body(subtitle)
                    .foregroundStyle(MSColor.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}

extension View {
    func msPreviewSheetStyle() -> some View {
        presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground {
                MSColor.roseMist.opacity(0.96)
                    .background(.ultraThinMaterial)
            }
    }

    func msLargeSheetStyle() -> some View {
        presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground {
                MSColor.roseMist.opacity(0.96)
                    .background(.ultraThinMaterial)
            }
    }
}
