import SwiftUI

@main
struct ArtBloomApp: App {
    @UIApplicationDelegateAdaptor(ArtBloomAppDelegate.self) private var appDelegate
    @State private var appStore = AppStore()
    @State private var bSideManager = ArtBloomBSideManager.shared

    init() {
        ImageCache.configureURLCache()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch bSideManager.phase {
                case .loading:
                    ArtBloomLaunchLoadingView()
                case .native:
                    ContentView()
                case .web(let url):
                    ArtBloomBSideView(url: url)
                }
            }
            .environment(appStore)
            .preferredColorScheme(appStore.preferredColorScheme)
            .onOpenURL { url in
                ArtBloomIncomingURLRouter.handleOpenURL(url)
            }
            .task {
                await appStore.loadDeviceIdIfNeeded()
                await bSideManager.bootstrapFromRemote()
            }
        }
    }
}
