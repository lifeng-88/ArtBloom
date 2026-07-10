import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var appStore
    @State private var selectedTab: Tab = .home
    @Namespace private var tabNamespace

    enum Tab: Int, CaseIterable {
        case home, workshop, canvas, studio

        var title: String {
            switch self {
            case .home: return L10n.tabHome
            case .workshop: return L10n.tabWorkshop
            case .canvas: return L10n.tabCanvas
            case .studio: return L10n.tabStudio
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .workshop: return "sparkles.rectangle.stack.fill"
            case .canvas: return "paintbrush.fill"
            case .studio: return "book.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            tabContent(HomeView(), tab: .home)
                .id(appStore.appLanguage)
            tabContent(WorkshopView(), tab: .workshop)
                .id(appStore.appLanguage)
            tabContent(DrawingCanvasView(), tab: .canvas)
                .id(appStore.appLanguage)
            tabContent(StudioProfileView(), tab: .studio)
                .id(appStore.appLanguage)
        }
        .environment(\.locale, appStore.resolvedLocale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .msBrandBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomChrome {
                VStack(spacing: 0) {
                    if selectedTab == .home {
                        HStack {
                            Spacer()
                            Button {
                                appStore.clearEditingSession()
                                appStore.pendingCanvasBackground = nil
                                selectedTab = .canvas
                                CanvasHaptics.medium()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(MSColor.onPrimary)
                                    .frame(width: 56, height: 56)
                                    .background(Circle().fill(MSGradient.primary))
                                    .shadow(color: MSColor.primary.opacity(0.35), radius: 10, y: 4)
                            }
                            .buttonStyle(PressScaleStyle())
                            .accessibilityLabel(L10n.startNewProject)
                            .padding(.trailing, 24)
                            .padding(.bottom, 8)
                        }
                    }
                    bottomNavBar
                }
            }
        }
        .onChange(of: selectedTab) { _, tab in
            if tab != .canvas {
                appStore.canvasFullscreen = false
            }
        }
        .environment(\.selectedTab, $selectedTab)
        .msToast()
    }

    private var showsBottomChrome: Bool {
        if selectedTab == .canvas && appStore.canvasFullscreen { return false }
        if selectedTab == .studio && appStore.studioDetailActive { return false }
        return true
    }

    @ViewBuilder
    private func tabContent<V: View>(_ view: V, tab: Tab) -> some View {
        view
            .opacity(selectedTab == tab ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }

    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                    CanvasHaptics.light()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        MSTypography.label(tab.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selectedTab == tab ? MSColor.onPrimary : MSColor.onSurfaceVariant.opacity(0.75))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(MSGradient.primary)
                                .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: MSLayout.tabBarHeight)
        .background {
            MSColor.roseMist.opacity(0.82)
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MSColor.blush.opacity(0.2))
                .frame(height: 1)
        }
    }
}

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<ContentView.Tab>? = nil
}

extension EnvironmentValues {
    var selectedTab: Binding<ContentView.Tab>? {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}
