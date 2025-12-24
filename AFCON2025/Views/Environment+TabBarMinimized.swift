import SwiftUI

// Environment key for indicating whether a tab bar is minimized.
// Provide a safe default and make the API available on all targets while
// allowing callers to gate usage by OS if needed.
private struct TabBarMinimizedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    // If your project needs to gate this behind newer OS versions,
    // you can add availability attributes here. Keeping it available
    // broadly lets older OSes compile and use the default.
    var tabBarMinimized: Bool {
        get { self[TabBarMinimizedKey.self] }
        set { self[TabBarMinimizedKey.self] = newValue }
    }
}

// Convenience view modifier to set the environment value in view hierarchies.
public extension View {
    func tabBarMinimized(_ minimized: Bool) -> some View {
        environment(\.tabBarMinimized, minimized)
    }
}
