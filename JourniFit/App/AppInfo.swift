import Foundation

enum AppInfo {
    static let name = "journi Fit"
    static let storeName = "journipod Fit: Workout"
    static let copyrightHolder = "journipod"
    static let urlScheme = "journifit"
    static let tagline = "Build routines. Lift. Beat your best."

    // Links for About. nil = not ready yet; the row shows the name only.
    // TODO: fill in before the App Store submit.
    static let supportEmail: String? = nil          // e.g. "support@journipod.com"
    static let privacyPolicyURL: URL? = nil         // required by App Store Connect
    static let appStoreID: String? = nil            // journi Fit, after the App Store record goes live
    static let journiDiaryURL: URL? = nil           // journi Diary App Store link, once it is live
    static let exerciseDataURL = URL(string: "https://github.com/yuhonas/free-exercise-db")!

    static var reviewURL: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)?action=write-review") }
    }

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
