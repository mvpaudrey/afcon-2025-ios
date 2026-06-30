import SwiftUI
import TournamentKit

struct FWCViewFactory: TournamentViewFactory {
    func makeHomeView() -> some View {
        FWCHomeView()
    }
}
