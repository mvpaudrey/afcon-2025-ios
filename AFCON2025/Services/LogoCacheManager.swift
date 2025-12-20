import Foundation
import CryptoKit

/// Handles caching club crest images into the shared app group so the widget can
/// render them without performing any network requests.
final class LogoCacheManager {
    static let shared = LogoCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL?
    private let usesAppGroupStorage: Bool

    private init() {
        if let container = AppGroup.containerURL {
            let directory = container.appendingPathComponent("Logos", isDirectory: true)
            cacheDirectory = directory
            usesAppGroupStorage = true
        } else {
            let fallback = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Logos", isDirectory: true)
            cacheDirectory = fallback
            usesAppGroupStorage = false
            if fallback == nil {
                print("LogoCacheManager: unable to resolve caches directory.")
            } else {
                print("LogoCacheManager: App Group container unavailable – using caches directory fallback.")
            }
        }

        if let cacheDirectory, !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("LogoCacheManager: failed to create cache directory – \(error)")
            }
        }
    }

    /// Downloads and caches the crest if it is not cached yet.
    /// - Parameter urlString: Remote URL provided by the API.
    /// - Returns: A stable identifier that can be passed to the widget (relative path when using an App Group).
    func cacheLogoIfNeeded(from urlString: String?) async -> String? {
        guard let urlString, !urlString.isEmpty else { return nil }
        guard let cacheDirectory else { return nil }

        let fileURL = cachedFileURL(for: urlString, baseDirectory: cacheDirectory)

        if fileManager.fileExists(atPath: fileURL.path) {
            return storageIdentifier(for: fileURL)
        }

        guard let remoteURL = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  !data.isEmpty else {
                return nil
            }

            try data.write(to: fileURL, options: [.atomic])
            return storageIdentifier(for: fileURL)
        } catch {
            print("LogoCacheManager: failed to cache logo – \(error)")
            return nil
        }
    }

    /// Returns the identifier for a logo if it has already been cached.
    func cachedLogoPath(for urlString: String?) -> String? {
        guard let urlString, !urlString.isEmpty,
              let cacheDirectory else { return nil }

        let fileURL = cachedFileURL(for: urlString, baseDirectory: cacheDirectory)
        return fileManager.fileExists(atPath: fileURL.path) ? storageIdentifier(for: fileURL) : nil
    }

    /// Resolves a stored identifier (relative path or absolute path) into a concrete filesystem path.
    func resolvePath(for storedPath: String?) -> String? {
        guard let storedPath, !storedPath.isEmpty else { return nil }

        if storedPath.hasPrefix("/") {
            return storedPath
        }

        if usesAppGroupStorage, let container = AppGroup.containerURL {
            return container.appendingPathComponent(storedPath).path
        }

        if let cacheDirectory {
            return cacheDirectory.appendingPathComponent(storedPath).path
        }

        return nil
    }

    private func cachedFileURL(for urlString: String, baseDirectory: URL) -> URL {
        let hash = sha256(urlString)
        let ext = URL(string: urlString)?.pathExtension
        let filename = (ext?.isEmpty ?? true) ? hash : "\(hash).\(ext!)"
        return baseDirectory.appendingPathComponent(filename)
    }

    private func storageIdentifier(for fileURL: URL) -> String {
        guard usesAppGroupStorage, let container = AppGroup.containerURL else {
            return fileURL.path
        }

        let containerPath = container.path
        let absolute = fileURL.path

        if absolute.hasPrefix(containerPath) {
            let startIndex = absolute.index(absolute.startIndex, offsetBy: containerPath.count)
            let trimmed = absolute[startIndex...]
            return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        return fileURL.path
    }

    private func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
