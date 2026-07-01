import Foundation
import Observation

@Observable
class FWCBracketViewModel {
    nonisolated(unsafe) static let shared = FWCBracketViewModel()

    var bracketMatches: FWCBracketMatches? = FWCBracketData.placeholderMatches
    var selectedRound: FWCBracketRound = .roundOf32
    var hasInitializedSelectedRound = false

    init() {}

    func determineCurrentRound() -> FWCBracketRound {
        let today = Date()
        let cal   = Calendar.current

        func d(_ year: Int, _ month: Int, _ day: Int) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: day))!
        }

        // Dates estimées FWC2026 — à mettre à jour avec le calendrier officiel FIFA
        if today >= d(2026, 7, 23) { return .final }
        if today >= d(2026, 7, 19) { return .semiFinals }
        if today >= d(2026, 7, 15) { return .quarterFinals }
        if today >= d(2026, 7,  9) { return .roundOf16 }
        if today >= d(2026, 7,  4) { return .roundOf32 }
        return .roundOf32
    }
}
