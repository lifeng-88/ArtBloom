import ImageIO
import os
import SwiftUI
import UIKit

// MARK: - Downsampling

enum ImageDownsampler {
    static func downsample(data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
        return thumbnail(from: source, pointSize: pointSize, scale: scale)
    }

    static func downsample(at url: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }
        return thumbnail(from: source, pointSize: pointSize, scale: scale)
    }

    static func load(at url: URL, targetSize: CGSize?, scale: CGFloat) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        if let targetSize, targetSize.width > 1, targetSize.height > 1 {
            if let downsampled = downsample(at: url, to: targetSize, scale: scale) {
                return downsampled
            }
            guard let full = UIImage(contentsOfFile: url.path) else { return nil }
            return resize(full, to: targetSize, scale: scale)
        }

        return UIImage(contentsOfFile: url.path)
    }

    static func decode(data: Data, targetSize: CGSize?, scale: CGFloat) -> UIImage? {
        if let targetSize, targetSize.width > 1, targetSize.height > 1 {
            if let downsampled = downsample(data: data, to: targetSize, scale: scale) {
                return downsampled
            }
            guard let full = UIImage(data: data) else { return nil }
            return resize(full, to: targetSize, scale: scale)
        }
        return UIImage(data: data)
    }

    static func resize(_ image: UIImage, to pointSize: CGSize, scale: CGFloat) -> UIImage {
        let pixelSize = CGSize(width: max(1, pointSize.width * scale), height: max(1, pointSize.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }

    private static func thumbnail(from source: CGImageSource, pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let maxPixel = max(pointSize.width, pointSize.height) * scale
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixel)
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Cache

final class ImageCache {
    static let shared = ImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let diskDirectory: URL
    private let session: URLSession
    private let memoryKeyLock = OSAllocatedUnfairLock(initialState: Set<String>())
    private let inFlight = InFlightCoordinator()

    private init() {
        memory.countLimit = 120
        memory.totalCostLimit = 64 * 1024 * 1024

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDirectory = caches.appendingPathComponent("ArtBloomImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 128 * 1024 * 1024,
            diskPath: "ArtBloomURLCache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        session = URLSession(configuration: config)
    }

    static func configureURLCache() {
        _ = shared
    }

    func memoryImage(forKey key: String) -> UIImage? {
        memory.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        memory.setObject(image, forKey: key as NSString, cost: cost)
        memoryKeyLock.withLock { $0.insert(key) }
    }

    func cachedLocalImage(from url: URL, targetSize: CGSize?) -> UIImage? {
        let key = cacheKey(prefix: "local", identifier: url.path, targetSize: targetSize)
        return memoryImage(forKey: key)
    }

    func removeLocalCache(for url: URL) {
        let path = url.path
        let keysToRemove = memoryKeyLock.withLock { keys in
            let matched = keys.filter { $0.contains(path) }
            keys.subtract(matched)
            return matched
        }
        for key in keysToRemove {
            memory.removeObject(forKey: key as NSString)
        }
    }

    func loadRemote(urlString: String, targetSize: CGSize?) async -> UIImage? {
        guard URL(string: urlString) != nil else { return nil }

        let normalizedSize = normalizedTargetSize(targetSize)
        let displayKey = cacheKey(prefix: "remote", identifier: urlString, targetSize: normalizedSize)

        if let cached = memoryImage(forKey: displayKey) { return cached }

        guard let data = await loadRemoteData(urlString: urlString), !data.isEmpty else { return nil }

        let scale = await MainActor.run { UIScreen.main.scale }
        let image = await Task.detached(priority: .userInitiated) {
            ImageDownsampler.decode(data: data, targetSize: normalizedSize, scale: scale)
        }.value

        if let image {
            store(image, forKey: displayKey)
        }
        return image
    }

    func loadImage(urlString: String, targetSize: CGSize?) async -> UIImage? {
        if urlString.hasPrefix("asset://") {
            let assetName = String(urlString.dropFirst("asset://".count))
            guard let image = UIImage(named: assetName) else { return nil }

            let normalizedSize = normalizedTargetSize(targetSize)
            guard let normalizedSize else { return image }

            let displayKey = cacheKey(prefix: "asset", identifier: assetName, targetSize: normalizedSize)
            if let cached = memoryImage(forKey: displayKey) { return cached }

            let scale = await MainActor.run { UIScreen.main.scale }
            let resized = await Task.detached(priority: .userInitiated) {
                ImageDownsampler.resize(image, to: normalizedSize, scale: scale)
            }.value
            store(resized, forKey: displayKey)
            return resized
        }

        if let url = URL(string: urlString), url.isFileURL {
            return await loadLocal(from: url, targetSize: targetSize)
        }

        return await loadRemote(urlString: urlString, targetSize: targetSize)
    }

    func loadLocal(from url: URL, targetSize: CGSize?) async -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let normalizedSize = normalizedTargetSize(targetSize)
        let key = cacheKey(prefix: "local", identifier: url.path, targetSize: normalizedSize)

        if let cached = memoryImage(forKey: key) { return cached }

        return await inFlight.coalesceLocal(key: key) { [self] in
            if let cached = memoryImage(forKey: key) { return cached }

            let scale = await MainActor.run { UIScreen.main.scale }
            let image = await Task.detached(priority: .userInitiated) {
                ImageDownsampler.load(at: url, targetSize: normalizedSize, scale: scale)
            }.value

            if let image { store(image, forKey: key) }
            return image
        }
    }

    private func loadRemoteData(urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        let dataKey = "remote-data:\(urlString)"

        let diskURL = diskFileURL(for: dataKey)
        if FileManager.default.fileExists(atPath: diskURL.path),
           let data = try? Data(contentsOf: diskURL), !data.isEmpty {
            return data
        }

        return await inFlight.coalesceRemoteData(key: dataKey) { [self] in
            if FileManager.default.fileExists(atPath: diskURL.path),
               let data = try? Data(contentsOf: diskURL), !data.isEmpty {
                return data
            }

            do {
                var request = URLRequest(url: url)
                request.setValue("ArtBloom/1.0", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await session.data(for: request)

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    return nil
                }
                guard !data.isEmpty, UIImage(data: data) != nil else { return nil }

                try? data.write(to: diskURL, options: .atomic)
                return data
            } catch {
                return nil
            }
        }
    }

    private func normalizedTargetSize(_ size: CGSize?) -> CGSize? {
        guard let size, size.width > 1, size.height > 1 else { return nil }
        return size
    }

    private func cacheKey(prefix: String, identifier: String, targetSize: CGSize?) -> String {
        if let targetSize {
            return "\(prefix):\(identifier)@\(Int(targetSize.width))x\(Int(targetSize.height))"
        }
        return "\(prefix):\(identifier)@full"
    }

    private func diskKey(_ key: String) -> String {
        let hash = key.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-") ?? key
        return hash
    }

    private func diskFileURL(for key: String) -> URL {
        diskDirectory.appendingPathComponent(diskKey(key))
    }

    func approximateDiskCacheByteCount() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: diskDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    func clearRemoteImageCaches() {
        memory.removeAllObjects()
        memoryKeyLock.withLock { keys in
            keys.removeAll()
        }
        if FileManager.default.fileExists(atPath: diskDirectory.path) {
            try? FileManager.default.removeItem(at: diskDirectory)
        }
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        session.configuration.urlCache?.removeAllCachedResponses()
    }
}

private actor InFlightCoordinator {
    private var remoteData: [String: Task<Data?, Never>] = [:]
    private var localImages: [String: Task<UIImage?, Never>] = [:]

    func coalesceRemoteData(key: String, work: @escaping @Sendable () async -> Data?) async -> Data? {
        if let existing = remoteData[key] {
            return await existing.value
        }
        let task = Task { await work() }
        remoteData[key] = task
        let result = await task.value
        remoteData[key] = nil
        return result
    }

    func coalesceLocal(key: String, work: @escaping @Sendable () async -> UIImage?) async -> UIImage? {
        if let existing = localImages[key] {
            return await existing.value
        }
        let task = Task { await work() }
        localImages[key] = task
        let result = await task.value
        localImages[key] = nil
        return result
    }
}

// MARK: - SwiftUI Views

struct RemoteImage: View {
    let url: String
    var contentMode: ContentMode = .fill
    var alignment: Alignment = .center
    var targetSize: CGSize?

    @State private var image: UIImage?
    @State private var failed = false
    @State private var retryToken = 0

    private var loadKey: String {
        let sizeKey: String
        if let targetSize, targetSize.width > 1, targetSize.height > 1 {
            sizeKey = "\(url)@\(Int(targetSize.width))x\(Int(targetSize.height))"
        } else {
            sizeKey = "\(url)@full"
        }
        return "\(sizeKey)#\(retryToken)"
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                    .transition(.opacity.animation(.easeOut(duration: 0.25)))
            } else if failed {
                imagePlaceholder(showError: true)
            } else {
                imagePlaceholder(showError: false)
            }
        }
        .clipped()
        .accessibilityLabel(failed ? L10n.imageLoadFailedRetry : "")
        .task(id: loadKey) {
            failed = false
            let loaded = await ImageCache.shared.loadImage(urlString: url, targetSize: targetSize)
            if let loaded {
                withAnimation(.easeOut(duration: 0.25)) {
                    image = loaded
                    failed = false
                }
            } else {
                image = nil
                failed = true
            }
        }
        .modifier(RemoteImageRetryTap(failed: failed) {
            retryToken += 1
        })
    }

    @ViewBuilder
    private func imagePlaceholder(showError: Bool) -> some View {
        Color.clear
            .background(MSColor.surfaceContainerHigh)
            .overlay {
                if showError {
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.4))
                        MSTypography.label(L10n.imageLoadFailedRetry)
                            .foregroundStyle(MSColor.onSurfaceVariant.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(8)
                } else {
                    MSShimmer()
                }
            }
    }
}

private struct RemoteImageRetryTap: ViewModifier {
    let failed: Bool
    let onRetry: () -> Void

    func body(content: Content) -> some View {
        if failed {
            content.onTapGesture(perform: onRetry)
        } else {
            content
        }
    }
}

struct LocalArtworkImage: View {
    let url: URL
    var contentMode: ContentMode = .fill
    var targetSize: CGSize?

    @State private var image: UIImage?

    private var loadKey: String {
        if let targetSize, targetSize.width > 1, targetSize.height > 1 {
            return "\(url.path)@\(Int(targetSize.width))x\(Int(targetSize.height))"
        }
        return "\(url.path)@full"
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            } else {
                MSColor.surfaceContainerHigh
                    .overlay { MSShimmer() }
            }
        }
        .frame(maxWidth: contentMode == .fill ? .infinity : nil)
        .frame(maxHeight: contentMode == .fill ? .infinity : nil)
        .clipped()
        .task(id: loadKey) {
            image = ImageCache.shared.cachedLocalImage(from: url, targetSize: targetSize)
            if image != nil { return }

            let loaded = await ImageCache.shared.loadLocal(from: url, targetSize: targetSize)
            if let loaded {
                withAnimation(.easeOut(duration: 0.2)) {
                    image = loaded
                }
            }
        }
    }
}

struct SizedRemoteImage: View {
    let url: String
    var contentMode: ContentMode = .fill

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            RemoteImage(
                url: url,
                contentMode: contentMode,
                targetSize: size.width > 1 && size.height > 1 ? size : nil
            )
            .frame(width: size.width, height: size.height)
        }
    }
}
