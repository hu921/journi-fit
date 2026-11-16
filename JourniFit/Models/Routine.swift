import Foundation
import SwiftData

// All properties have defaults and relationships are optional
// so the store can sync with iCloud (CloudKit) as a backup.

@Model
final class Routine {
    var name: String = ""
    var notes: String = ""
    var createdAt: Date = Date.now
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var items: [RoutineExercise]? = []

    init(name: String, notes: String = "") {
        self.name = name
        self.notes = notes
    }

    var sortedItems: [RoutineExercise] {
        (items ?? []).sorted { $0.order < $1.order }
    }
}

@Model
final class RoutineExercise {
    var exerciseID: String = ""
    var order: Int = 0
    var sets: Int = 3
    var reps: Int = 10
    /// Rest between sets, in seconds.
    var restSeconds: Int = 90
    var weight: Double = 0
    var routine: Routine?

    init(exerciseID: String, order: Int, sets: Int = 3, reps: Int = 10, restSeconds: Int = 90, weight: Double = 0) {
        self.exerciseID = exerciseID
        self.order = order
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.weight = weight
    }

    var exercise: Exercise? { ExerciseLibrary.shared.exercise(id: exerciseID) }
}
