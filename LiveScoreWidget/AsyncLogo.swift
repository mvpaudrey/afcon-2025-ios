import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// Type-erased shape wrapper
struct AnyShape: Shape {
    private let base: any Shape

    init<S: Shape>(_ shape: S) {
        self.base = shape
    }

    func path(in rect: CGRect) -> Path {
        base.path(in: rect)
    }
}

struct LogoImageView: View {
    let path: String?
    var size: CGSize = CGSize(width: 32, height: 32)
    var useCircle: Bool = true

    var body: some View {
        Group {
            if let path, !path.isEmpty, imageExists(path) {
                Image(path)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(useCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 6)))
        .overlay(
            useCircle ?
                AnyShape(Circle()).stroke(Color.gray.opacity(0.2), lineWidth: 0.5) :
                AnyShape(RoundedRectangle(cornerRadius: 6)).stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }

    private func imageExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return NSImage(named: name) != nil
        #endif
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

