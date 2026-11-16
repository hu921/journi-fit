import Foundation
import SwiftData

/// The user's gym: name and location. One per user in version 1.
@Model
final class GymProfile {
    var name: String = ""
    var location: String = ""
    var createdAt: Date = Date.now

    init(name: String = "", location: String = "") {
        self.name = name
        self.location = location
    }
}

/// A machine saved to "My Gym", with the user's own settings.
/// Either linked to an exercise in the database (exerciseID),
/// or a custom machine the database does not have (customName).
@Model
final class GymMachine {
    var exerciseID: String = ""
    /// Name of a custom machine. Empty when linked to the database.
    var customName: String = ""
    /// Main muscle of a custom machine, e.g. "chest".
    var customMuscle: String = ""
    /// The user's label, e.g. "Row 2 near the window".
    var nickname: String = ""
    /// Seat height, pin position, etc.
    var settings: String = ""
    var lastWeight: Double = 0
    @Attribute(.externalStorage) var photo: Data?
    var addedAt: Date = Date.now

    init(exerciseID: String = "", customName: String = "", customMuscle: String = "",
         nickname: String = "", settings: String = "") {
        self.exerciseID = exerciseID
        self.customName = customName
        self.customMuscle = customMuscle
        self.nickname = nickname
        self.settings = settings
    }

    var exercise: Exercise? { ExerciseLibrary.shared.exercise(id: exerciseID) }
    var isCustom: Bool { exercise == nil }

    var displayName: String {
        if !nickname.isEmpty { return nickname }
        if let exercise { return exercise.name }
        return customName.isEmpty ? "Machine" : customName
    }

    /// Muscles used to suggest substitutes.
    var muscles: [String] {
        exercise?.primaryMuscles ?? (customMuscle.isEmpty ? [] : [customMuscle.lowercased()])
    }
}
