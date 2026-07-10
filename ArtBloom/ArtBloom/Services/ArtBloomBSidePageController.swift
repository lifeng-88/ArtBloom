import UIKit
import WebKit

final class ArtBloomBSidePageController: UIViewController {
    private let url: URL
    private let pageTitle: String
    private var progressObservation: NSKeyValueObservation?

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(ArtBloomBSideMediaCacheSchemeHandler(), forURLScheme: ArtBloomBSideMediaCacheSchemeHandler.scheme)
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        ArtBloomBSideConfig.configureWebView(webView)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }()

    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.progressTintColor = UIColor(red: 0.79, green: 0.48, blue: 0.52, alpha: 1)
        view.trackTintColor = .clear
        return view
    }()

    init(url: URL, title: String) {
        self.url = url
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1, green: 0.96, blue: 0.97, alpha: 1)
        configureLayout()
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            let progress = Float(webView.estimatedProgress)
            self?.progressView.setProgress(progress, animated: true)
            self?.progressView.isHidden = progress >= 1
        }
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    private func configureLayout() {
        let header = UIView()
        header.backgroundColor = UIColor(red: 1, green: 0.94, blue: 0.95, alpha: 1)
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = pageTitle.isEmpty ? ArtBloomBSideConfig.appDisplayName : pageTitle
        titleLabel.textColor = UIColor(red: 0.29, green: 0.18, blue: 0.21, alpha: 1)
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor(red: 0.45, green: 0.31, blue: 0.35, alpha: 1)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        header.addSubview(closeButton)
        header.addSubview(titleLabel)
        view.addSubview(progressView)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 54),

            closeButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 14),
            closeButton.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -9),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -62),

            progressView.topAnchor.constraint(equalTo: header.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

enum ArtBloomBSidePagePresenter {
    @MainActor
    static func presentBrowser(url: URL, title: String) -> Bool {
        guard let presenter = topViewController() else { return false }
        let controller = ArtBloomBSidePageController(url: url, title: title)
        controller.modalPresentationStyle = .fullScreen
        presenter.present(controller, animated: true)
        return true
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
