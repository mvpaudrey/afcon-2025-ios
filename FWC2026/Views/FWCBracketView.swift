import SwiftUI
import TournamentKit

public struct FWCBracketView: View {
    public var body: some View {
        ContentUnavailableView(
            "Bracket — Coming Soon",
            systemImage: "chart.bar.doc.horizontal"
        )
    }
}

#Preview {
    FWCBracketView()
}
