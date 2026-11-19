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

/// One exercise in a routine. Holds its own list of sets.
@Model
final class RoutineExercise {
    var exerciseID: String = ""
    var order: Int = 0
    /// Rest between sets, in seconds.
    var restSeconds: Int = 90
    var routine: Routine?
    @Relationship(deleteRule: .cascade, inverse: \RoutineSet.routineExercise)
    var sets: [RoutineSet]? = []

    init(exerciseID: String, order: Int, restSeconds: Int = 90) {
        self.exerciseID = exerciseID
        self.order = order
        self.restSeconds = restSeconds
    }

    var exercise: Exercise? { ExerciseLibrary.shared.exercise(id: exerciseID) }

    var sortedSets: [RoutineSet] {
        (sets ?? []).sorted { $0.order < $1.order }
    }
}

/// One set: target weight and reps.
@Model
final class RoutineSet {
    var order: Int = 0
    var weight: Double = 0
    var reps: Int = 10
    var routineExercise: RoutineExercise?

    init(order: Int, weight: Double = 0, reps: Int = 10) {
        self.order = order
        self.weight = weight
        self.reps = reps
    }
}
