import Foundation
import SwiftData

/// A workout session started from a routine.
/// endedAt == nil means the workout is still running.
@Model
final class Workout {
    var routineName: String = ""
    var startedAt: Date = Date.now
    var endedAt: Date?
    /// Routine it was started from (kept as a weak link; routine may be deleted later).
    var routineCreatedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]? = []

    init(routineName: String, routineCreatedAt: Date?) {
        self.routineName = routineName
        self.routineCreatedAt = routineCreatedAt
    }

    var isActive: Bool { endedAt == nil }

    /// Total time in seconds (up to now if still running).
    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }

    var sortedExercises: [WorkoutExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }

    var completedSets: Int {
        sortedExercises.reduce(0) { $0 + $1.sortedSets.filter(\.done).count }
    }

    /// Total weight lifted in completed sets.
    var volume: Double {
        sortedExercises.flatMap(\.sortedSets).filter(\.done)
            .reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    /// Copies the routine's exercises and sets into a new workout.
    static func start(from routine: Routine, in context: ModelContext) -> Workout {
        let workout = Workout(routineName: routine.name, routineCreatedAt: routine.createdAt)
        context.insert(workout)
        for item in routine.sortedItems {
            let we = WorkoutExercise(exerciseID: item.exerciseID, order: item.order,
                                     restSeconds: item.restSeconds)
            we.workout = workout
            context.insert(we)
            for s in item.sortedSets {
                let ws = WorkoutSet(order: s.order, weight: s.weight, reps: s.reps)
                ws.workoutExercise = we
                context.insert(ws)
            }
        }
        return workout
    }
}

@Model
final class WorkoutExercise {
    var exerciseID: String = ""
    var order: Int = 0
    var restSeconds: Int = 90
    var workout: Workout?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet]? = []

    init(exerciseID: String, order: Int, restSeconds: Int) {
        self.exerciseID = exerciseID
        self.order = order
        self.restSeconds = restSeconds
    }

    var exercise: Exercise? { ExerciseLibrary.shared.exercise(id: exerciseID) }

    var sortedSets: [WorkoutSet] {
        (sets ?? []).sorted { $0.order < $1.order }
    }
}

@Model
final class WorkoutSet {
    var order: Int = 0
    var weight: Double = 0
    var reps: Int = 0
    var done: Bool = false
    var workoutExercise: WorkoutExercise?

    init(order: Int, weight: Double, reps: Int) {
        self.order = order
        self.weight = weight
        self.reps = reps
    }
}

extension TimeInterval {
    /// 1:05:09 or 5:09
    var clockString: String {
        let t = Int(self.rounded(.down))
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// 1h 5m or 12m
    var shortString: String {
        let t = Int(self) / 60
        return t >= 60 ? "\(t / 60)h \(t % 60)m" : "\(t)m"
    }
}
