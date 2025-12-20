import SwiftUI

struct QuickStatsBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Morocco")
                            .fontWeight(.semibold)
                        Text("2-1")
                        Text("Algeria")
                            .fontWeight(.semibold)
                        Text("67'")
                            .opacity(0.7)
                    }
                    .font(.caption)
                    
                    HStack(spacing: 4) {
                        Text("Next:")
                        Text("Morocco vs Senegal")
                            .fontWeight(.semibold)
                        Text("Jan 20, 20:00")
                            .opacity(0.7)
                    }
                    .font(.caption2)
                }
                
                Spacer()
                
                Text("Live updates")
                    .font(.caption2)
                    .opacity(0.7)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color("moroccoRed"), Color("moroccoGreen")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
