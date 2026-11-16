import Foundation
import SwiftData

/// A machine saved to "My gym", with the user's own settings.
@Model
final class GymMachine {
    var exerciseID: String = ""
    /// The user's label, e.g. "Row 2 near the window".
    var nickname: String = ""
    /// Seat height, pin position, etc.
    var settings: String = ""
    var lastWeight: Double = 0
    var addedAt: Date = Date.now

    init(exerciseID: String, nickname: String = "", settings: String = "") {
        self.exerciseID = exerciseID
        self.nickname = nickname
        self.settings = settings
    }

    var exercise: Exercise? { ExerciseLibrary.shared.exercise(id: exerciseID) }
}
