import Foundation

public enum AppGroup {
    /// Shared app group identifier used by the main app and widget extension.
    /// Make sure this matches the value configured in the Signing & Capabilities tab.
    public static let identifier = "group.com.cheulah.afcon"

    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
