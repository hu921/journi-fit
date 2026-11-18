import Foundation

/// An exercise from the bundled open exercise database (read-only).
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    /// Display name, "Name (Equipment)". Set by scripts/exercise_names.py.
    let name: String
    /// Name in the source database. Still searchable.
    let originalName: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: String
    /// Gym machine name, if the exercise uses one (e.g. "Lat pulldown machine").
    let machine: String?
    let level: String
    let instructions: [String]
    /// Image file names in the app bundle. Empty means show a placeholder.
    let images: [String]
    /// Position in the popular list (1 = most popular). nil = not on the list.
    let popularRank: Int?

    var allMuscles: [String] { primaryMuscles + secondaryMuscles }

    var equipmentLabel: String { Exercise.label(forEquipment: equipment) }

    /// Readable name for a raw equipment value from the database.
    static func label(forEquipment raw: String) -> String {
        switch raw {
        case "body only": return "Bodyweight"
        case "none": return "No equipment"
        case "kettlebells": return "Kettlebell"
        case "bands": return "Band"
        case "e-z curl bar": return "EZ Bar"
        case "foam roll": return "Foam Roller"
        default: return raw.capitalized
        }
    }
}
