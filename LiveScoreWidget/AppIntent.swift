import WidgetKit
import AppIntents

struct SelectMatchIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Live Match" }
    static var description: IntentDescription {
        IntentDescription("Choose which live match the widget should display.")
    }

    @Parameter(title: "Match")
    var match: LiveMatchSelection?

    // Keep the summary simple and compatible
    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$match)")
    }
}

struct LiveMatchSelection: AppEntity, Hashable {
    // AppEntity requires an ID that conforms to EntityIdentifierConvertible.
    // String already conforms, so map our Int32 id to String for intents.
    typealias ID = String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Match")
    }

    static let defaultQuery = LiveMatchQuery()

    let fixtureID: Int32
    let title: String
    let subtitle: String

    // AppEntity id exposed to AppIntents
    var id: ID { String(fixtureID) }

    var displayRepresentation: DisplayRepresentation {
        let titleResource = LocalizedStringResource(stringLiteral: title)
        if subtitle.isEmpty {
            return DisplayRepresentation(title: titleResource)
        }
        let subtitleResource = LocalizedStringResource(stringLiteral: subtitle)
        return DisplayRepresentation(title: titleResource, subtitle: subtitleResource)
    }

    init(id: Int32, title: String, subtitle: String) {
        self.fixtureID = id
        self.title = title
        self.subtitle = subtitle
    }

    init(snapshot: LiveMatchWidgetSnapshot) {
        self.init(
            id: snapshot.fixtureID,
            title: "\(snapshot.homeTeam) vs \(snapshot.awayTeam)",
            subtitle: "\(snapshot.competition) · \(snapshot.status)"
        )
    }
}

struct LiveMatchQuery: EntityQuery {
    typealias Entity = LiveMatchSelection

    func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
        let snapshots = HomeWidgetSnapshotStore.shared.snapshots()
        let lookup = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.fixtureID, LiveMatchSelection(snapshot: $0)) })
        // Convert String identifiers back to Int32
        return identifiers.compactMap { str in
            guard let intID = Int32(str) else { return nil }
            return lookup[intID]
        }
    }

    func suggestedEntities() async throws -> [Entity] {
        HomeWidgetSnapshotStore.shared.snapshots().map { LiveMatchSelection(snapshot: $0) }
    }

    func defaultResult() -> Entity? {
        HomeWidgetSnapshotStore.shared.snapshots().first.map { LiveMatchSelection(snapshot: $0) }
    }
}
