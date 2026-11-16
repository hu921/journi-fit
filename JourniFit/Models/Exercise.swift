import Foundation

/// An exercise from the bundled open exercise database (read-only).
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: String
    /// Gym machine name, if the exercise uses one (e.g. "Lat pulldown machine").
    let machine: String?
    let level: String
    let instructions: [String]
    /// Image file names in the app bundle. Empty means show a placeholder.
    let images: [String]

    var allMuscles: [String] { primaryMuscles + secondaryMuscles }
}
