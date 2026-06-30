import SwiftUI
import TournamentKit

struct AFCONViewFactory: TournamentViewFactory {
    func makeHomeView() -> some View {
        AFCONHomeView()
    }
}
