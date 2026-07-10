import SwiftUI

struct MSToast: View {
    let message: String
    let style: MSToastStyle

    private var iconName: String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch style {
        case .success: return MSColor.primary
        case .error: return MSColor.error
        case .info: return MSColor.secondary
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            MSTypography.label(message)
                .foregroundStyle(MSColor.onSurface)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(MSColor.surfaceContainerLowest.opacity(0.95))
                .overlay {
                    Capsule().strokeBorder(MSColor.blush.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: MSColor.primary.opacity(0.12), radius: MSShadow.cardRadius, y: 4)
        }
        .padding(.top, 8)
        .accessibilityLabel(message)
    }
}

struct MSToastModifier: ViewModifier {
    @Environment(AppStore.self) private var appStore

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = appStore.toastMessage {
                    MSToast(message: message, style: appStore.toastStyle)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .animation(.easeOut(duration: 0.25), value: appStore.toastMessage)
    }
}

extension View {
    func msToast() -> some View {
        modifier(MSToastModifier())
    }
}
