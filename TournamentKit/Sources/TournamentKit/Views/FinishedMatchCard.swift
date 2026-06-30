//
//  Compact card view for finished matches
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import AFCONClient

public struct FinishedMatchCard: View {
    public let match: LiveMatchData
    @Environment(\.colorScheme) private var colorScheme

    public init(match: LiveMatchData) {
        self.match = match
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Full Time Badge
            HStack {
                Text("Finished")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(4)

                Spacer()

                Text("Fixture #\(match.fixtureID)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Compact Score Display
            HStack(alignment: .center, spacing: 20) {
                TeamResultColumn(
                    name: match.homeTeamName,
                    score: match.homeScore,
                    logoPath: match.homeTeamLogoPath,
                    nameColor: homeTeamColor,
                    scoreColor: homeScoreColor,
                    alignment: .trailing
                )

                Text("-")
                    .font(.title3)
                    .foregroundColor(.secondary)

                TeamResultColumn(
                    name: match.awayTeamName,
                    score: match.awayScore,
                    logoPath: match.awayTeamLogoPath,
                    nameColor: awayTeamColor,
                    scoreColor: awayScoreColor,
                    alignment: .leading
                )
            }

            // Key Stats Summary
            if !match.recentEvents.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                HStack(spacing: 12) {
                    // Goals count
                    HStack(spacing: 4) {
                        Image(systemName: "soccerball.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(goalCount) goal\(goalCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Cards count
                    if cardCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "square.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("\(cardCount) card\(cardCount == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Substitutions count
                    if substitutionCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("\(substitutionCount) sub\(substitutionCount == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }

        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Computed Properties

    private var goalCount: Int {
        match.recentEvents.filter { $0.type.lowercased() == "goal" }.count
    }

    private var cardCount: Int {
        match.recentEvents.filter { $0.type.lowercased() == "card" }.count
    }

    private var substitutionCount: Int {
        match.recentEvents.filter { $0.type.lowercased() == "subst" }.count
    }

    private var homeIsWinner: Bool {
        match.homeScore > match.awayScore
    }

    private var awayIsWinner: Bool {
        match.awayScore > match.homeScore
    }

    private var highlightColor: Color {
        if colorScheme == .dark {
            return Color(.systemGreen)
        }
        return Color(red: 0.0, green: 0.45, blue: 0.25)
    }

    private var neutralColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.primary.opacity(0.65)
    }

    private var homeTeamColor: Color {
        if homeIsWinner { return highlightColor }
        if awayIsWinner { return neutralColor }
        return .primary
    }

    private var awayTeamColor: Color {
        if awayIsWinner { return highlightColor }
        if homeIsWinner { return neutralColor }
        return .primary
    }

    private var homeScoreColor: Color {
        homeIsWinner ? highlightColor : (awayIsWinner ? neutralColor : .primary)
    }

    private var awayScoreColor: Color {
        awayIsWinner ? highlightColor : (homeIsWinner ? neutralColor : .primary)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

}

private struct TeamResultColumn: View {
    let name: String
    let score: Int32
    let logoPath: String?
    let nameColor: Color
    let scoreColor: Color
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            TeamLogoView(path: logoPath, size: CGSize(width: 36, height: 36))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(nameColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: 110, alignment: alignment == .leading ? .leading : .trailing)

            Text("\(score)")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(scoreColor)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

private struct TeamLogoView: View {
    let path: String?
    var size: CGSize

    var body: some View {
        ZStack {
            if let image = loadImage() {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "shield")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadImage() -> Image? {
        #if canImport(UIKit)
        guard let uiImage = loadUIImage() else { return nil }
        return Image(uiImage: uiImage)
        #else
        guard let nsImage = loadNSImage() else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }

    #if canImport(UIKit)
    private func loadUIImage() -> UIImage? {
        guard let path, !path.isEmpty else { return nil }
        if FileManager.default.fileExists(atPath: path) {
            return UIImage(contentsOfFile: path)
        }
        return UIImage(contentsOfFile: resolveRelativePath(path))
    }
    #else
    private func loadNSImage() -> NSImage? {
        guard let path, !path.isEmpty else { return nil }
        if FileManager.default.fileExists(atPath: path) {
            return NSImage(contentsOfFile: path)
        }
        return NSImage(contentsOfFile: resolveRelativePath(path))
    }
    #endif

    private func resolveRelativePath(_ relativePath: String) -> String {
        if relativePath.hasPrefix("/") {
            return relativePath
        }

        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier) {
            return container.appendingPathComponent(relativePath).path
        }

        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return caches.appendingPathComponent(relativePath).path
        }

        return relativePath
    }
}
