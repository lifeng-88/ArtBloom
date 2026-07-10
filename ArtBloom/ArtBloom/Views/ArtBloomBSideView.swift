import SwiftUI
import WebKit

@MainActor
final class ArtBloomBSideViewModel: NSObject, ObservableObject, ArtBloomBSideBridgeHost {
    @Published var isReady = false
    @Published var errorMessage: String?
    @Published var bridgeToastMessage: String?

    let pageURL: URL
    private var bridge: ArtBloomBSideBridge?
    private var didLoad = false
    private var keyboardObservers: [NSObjectProtocol] = []
    private var readyFallbackWorkItem: DispatchWorkItem?
    private var loadSequence = 0

    var hostWebView: WKWebView { webView }

    private(set) lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        let bridge = ArtBloomBSideBridge(host: self)
        self.bridge = bridge
        contentController.add(bridge, name: ArtBloomBSideBridge.messageName)

        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(ArtBloomBSideMediaCacheSchemeHandler(), forURLScheme: ArtBloomBSideMediaCacheSchemeHandler.scheme)
        configuration.userContentController = contentController
        ArtBloomBSidePeachGenBootstrap.install(
            on: contentController,
            cfgURL: ArtBloomBSideConfig.runtimeConfigURL
        )
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        ArtBloomBSideConfig.configureWebView(webView)
        webView.navigationDelegate = bridge
        webView.uiDelegate = bridge
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        installKeyboardScrollGuard(for: webView)
        return webView
    }()

    init(pageURL: URL) {
        self.pageURL = pageURL
        super.init()
    }

    deinit {
        keyboardObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        ArtBloomPaymentManager.shared.startListening()
        Task {
            await loadResolvedURL()
        }
    }

    func reload() {
        isReady = false
        errorMessage = nil
        ArtBloomPaymentManager.shared.startListening()
        Task { await loadResolvedURL() }
    }

    func markWebReady() {
        readyFallbackWorkItem?.cancel()
        isReady = true
        errorMessage = nil
    }

    func failWebLoad(_ message: String) {
        readyFallbackWorkItem?.cancel()
        isReady = false
        errorMessage = message
    }

    func navigationFinished() {
        let sequence = loadSequence
        readyFallbackWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.loadSequence == sequence, !self.isReady else { return }
            self.markWebReady()
        }
        readyFallbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: workItem)
    }

    func switchToNative() {
        ArtBloomBSideManager.shared.switchToNative()
    }

    func showBridgeToast(_ message: String) {
        bridgeToastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            if self?.bridgeToastMessage == message {
                self?.bridgeToastMessage = nil
            }
        }
    }

    private func loadResolvedURL() async {
        let deviceId = await ArtBloomDeviceManager.shared.getDeviceId()
        let url = ArtBloomBSideConfig.urlAppendingLaunchParams(
            pageURL,
            channel: ArtBloomBSideConfig.channel,
            deviceId: deviceId
        )
        load(url: url)
    }

    private func load(url: URL) {
        errorMessage = nil
        isReady = false
        readyFallbackWorkItem?.cancel()
        loadSequence += 1

        #if DEBUG
        if ArtBloomBSideConfig.debugLogging {
            print("📱 [ArtBloomBSideView] load \(url.absoluteString)")
        }
        let cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        #else
        let cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
        #endif

        webView.load(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 20))
    }

    private func installKeyboardScrollGuard(for webView: WKWebView) {
        let center = NotificationCenter.default
        let notifications: [Notification.Name] = [
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardDidChangeFrameNotification,
            UIResponder.keyboardWillHideNotification,
            UIResponder.keyboardDidHideNotification
        ]

        keyboardObservers = notifications.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak webView] _ in
                guard let webView else { return }
                webView.scrollView.contentInset = .zero
                webView.scrollView.scrollIndicatorInsets = .zero
                webView.scrollView.setContentOffset(.zero, animated: false)
            }
        }
    }
}

struct ArtBloomBSideView: View {
    let url: URL

    @StateObject private var viewModel: ArtBloomBSideViewModel
    @State private var secretTapCount = 0
    @State private var resetTask: Task<Void, Never>?

    init(url: URL) {
        self.url = url
        _viewModel = StateObject(wrappedValue: ArtBloomBSideViewModel(pageURL: url))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArtBloomBSideWebView(viewModel: viewModel)
                .opacity(viewModel.isReady ? 1 : 0)
                .ignoresSafeArea(edges: .bottom)

            if !viewModel.isReady, viewModel.errorMessage == nil {
                bSideLoadingView
            }

            if let errorMessage = viewModel.errorMessage {
                bSideErrorView(message: errorMessage) {
                    viewModel.reload()
                }
            }

            #if DEBUG
            Button {
                ArtBloomBSideManager.shared.switchToNative()
            } label: {
                MSTypography.label(L10n.settingsBSideClose)
                    .foregroundStyle(MSColor.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(MSColor.primaryContainer.opacity(0.55)))
            }
            .padding(.leading, 12)
            .padding(.bottom, 20)
            #else
            Color.clear
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
                .onTapGesture { registerExitTap() }
                .padding(.leading, 8)
                .padding(.bottom, 16)
            #endif
        }
        .background(MSColor.roseMist.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(alignment: .top) {
            if let message = viewModel.bridgeToastMessage {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MSColor.onPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(MSColor.primary.opacity(0.92)))
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.bridgeToastMessage)
    }

    private var bSideLoadingView: some View {
        VStack(spacing: 16) {
            Image("LaunchIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
            ProgressView()
                .tint(MSColor.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MSColor.roseMist)
    }

    private func bSideErrorView(message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(MSColor.primary.opacity(0.7))
            MSTypography.headline(L10n.bsideLoadFailed)
                .foregroundStyle(MSColor.onSurface)
            MSTypography.body(message)
                .foregroundStyle(MSColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            PillButton(title: L10n.retry, icon: "arrow.clockwise", style: .primary, action: retry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MSColor.roseMist.opacity(0.96))
    }

    private func registerExitTap() {
        secretTapCount += 1
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            secretTapCount = 0
        }
        guard secretTapCount >= 7 else { return }
        secretTapCount = 0
        resetTask?.cancel()
        ArtBloomBSideManager.shared.switchToNative()
    }
}

private struct ArtBloomBSideWebView: UIViewRepresentable {
    @ObservedObject var viewModel: ArtBloomBSideViewModel

    func makeUIView(context: Context) -> WKWebView {
        viewModel.loadIfNeeded()
        return viewModel.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
