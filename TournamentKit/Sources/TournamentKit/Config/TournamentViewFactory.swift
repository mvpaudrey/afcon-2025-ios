import SwiftUI

public protocol TournamentViewFactory {
    associatedtype HomeViewType: View
    @ViewBuilder func makeHomeView() -> HomeViewType
}
