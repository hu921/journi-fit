import Foundation

enum AppInfo {
    static let name = "journi Fit"
    static let storeName = "journipod Fit: Workout"
    static let copyrightHolder = "journipod"
    static let urlScheme = "journifit"

    static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    static var copyright: String {
        let year = Calendar.current.component(.year, from: .now)
        return "© \(year) \(copyrightHolder)"
    }
}
