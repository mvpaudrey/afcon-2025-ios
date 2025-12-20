import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct LogoImageView: View {
    let path: String?
    var size: CGSize = CGSize(width: 32, height: 32)

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

#if canImport(UIKit)
    private func loadImage() -> UIImage? {
        guard let resolvedPath = resolvePath() else { return nil }
        return UIImage(contentsOfFile: resolvedPath)
    }
#else
    private func loadImage() -> NSImage? {
        guard let resolvedPath = resolvePath() else { return nil }
        return NSImage(contentsOfFile: resolvedPath)
    }
#endif

    private func resolvePath() -> String? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("/") {
            return path
        }

        // Must match the identifier declared in AppGroup.swift
        let identifier = AppGroup.identifier
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return container.appendingPathComponent(path).path
        }

        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return caches.appendingPathComponent(path).path
        }

        return nil
    }

    private var placeholder: some View {
        ZStack {
            Color(.tertiarySystemBackground)
            Image(systemName: "soccerball")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
                .padding(6)
        }
    }
}
