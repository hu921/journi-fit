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
            // Baseline: last time's weight and reps for this exercise, set by set.
            let last = LastPerformance.sets(for: item.exerciseID, in: context) ?? []
            for (i, s) in item.sortedSets.enumerated() {
                let prev: LastPerformance.SetValues? = i < last.count ? Optional(last[i]) : last.last
                let ws = WorkoutSet(order: s.order,
                                    weight: prev?.weight ?? s.weight,
                                    reps: prev?.reps ?? s.reps)
                ws.previousWeight = prev?.weight
                ws.previousReps = prev?.reps
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
    /// Last time's values for this set, shown as a reference.
    var previousWeight: Double?
    var previousReps: Int?
    var workoutExercise: WorkoutExercise?

    init(order: Int, weight: Double, reps: Int) {
        self.order = order
        self.weight = weight
        self.reps = reps
    }
}

/// The most recent weight and reps a user did for an exercise.
enum LastPerformance {
    typealias SetValues = (weight: Double, reps: Int)

    /// Completed sets from the latest finished workout that included this exercise.
    static func sets(for exerciseID: String, in context: ModelContext) -> [SetValues]? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        guard let workouts = try? context.fetch(descriptor) else { return nil }
        for workout in workouts {
            for item in workout.sortedExercises where item.exerciseID == exerciseID {
                let done = item.sortedSets.filter(\.done)
                if !done.isEmpty { return done.map { ($0.weight, $0.reps) } }
            }
        }
        return nil
    }

    /// "135 × 8, 135 × 8, 125 × 10"
    static func summary(for exerciseID: String, in context: ModelContext) -> String? {
        guard let sets = sets(for: exerciseID, in: context) else { return nil }
        return sets.map { "\($0.weight.formatted()) × \($0.reps)" }.joined(separator: ", ")
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

// MARK: - Updating the routine after a workout

extension Workout {
    /// The routine this workout was started from, if it still exists.
    func sourceRoutine(in context: ModelContext) -> Routine? {
        guard let created = routineCreatedAt else { return nil }
        let descriptor = FetchDescriptor<Routine>(predicate: #Predicate { $0.createdAt == created })
        return try? context.fetch(descriptor).first
    }

    /// True when exercises were added, removed, replaced or reordered, or the
    /// number of sets or the rest time changed. Weight and reps alone do not count.
    func changedPlan(comparedTo routine: Routine) -> Bool {
        let mine = sortedExercises.map { "\($0.exerciseID)|\($0.sortedSets.count)|\($0.restSeconds)" }
        let theirs = routine.sortedItems.map { "\($0.exerciseID)|\($0.sortedSets.count)|\($0.restSeconds)" }
        return mine != theirs
    }

    /// Makes the routine match this workout: exercises, order, sets (weight and reps), rest.
    func updateRoutine(_ routine: Routine, in context: ModelContext) {
        for item in routine.items ?? [] { context.delete(item) }
        for (i, we) in sortedExercises.enumerated() {
            let item = RoutineExercise(exerciseID: we.exerciseID, order: i, restSeconds: we.restSeconds)
            item.routine = routine
            context.insert(item)
            for (j, ws) in we.sortedSets.enumerated() {
                let set = RoutineSet(order: j, weight: ws.weight, reps: ws.reps)
                set.routineExercise = item
                context.insert(set)
            }
        }
    }
}
