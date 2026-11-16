import SwiftUI
import SwiftData

/// The workouts done on one day. Tap one to see its exercises and sets.
struct DayWorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt)
    private var all: [Workout]
    let day: Date

    private var workouts: [Workout] {
        all.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: day) }
    }

    var body: some View {
        List {
            ForEach(workouts) { w in
                NavigationLink { WorkoutDetailView(workout: w) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.routineName.isEmpty ? "Workout" : w.routineName).font(.headline)
                        Text("\(w.startedAt.formatted(date: .omitted, time: .shortened)) · \(w.duration.clockString) · \(w.completedSets) sets")
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                }
            }
            .onDelete { offsets in
                let list = workouts
                offsets.map { list[$0] }.forEach(context.delete)
            }
        }
        .navigationTitle(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A finished workout: time, totals, and each exercise's sets.
struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        List {
            Section {
                LabeledContent("Started", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
                LabeledContent("Total time", value: workout.duration.clockString)
                LabeledContent("Sets done", value: "\(workout.completedSets)")
                LabeledContent("Volume", value: workout.volume.formatted(.number.precision(.fractionLength(0))))
            }
            ForEach(workout.sortedExercises) { item in
                Section {
                    ForEach(Array(item.sortedSets.enumerated()), id: \.element.id) { i, set in
                        HStack {
                            Text("\(i + 1)").bold().frame(width: 30, alignment: .leading)
                            Text("\(set.weight.formatted()) × \(set.reps)")
                            Spacer()
                            Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(set.done ? Theme.success : Theme.muted)
                        }
                    }
                } header: {
                    HStack(spacing: 10) {
                        if let ex = item.exercise {
                            ExerciseImage(exercise: ex).frame(width: 32, height: 32).clipShape(Circle())
                        }
                        Text(item.exercise?.name ?? "Exercise")
                            .font(.headline).foregroundStyle(Theme.text).textCase(nil)
                    }
                }
            }
        }
        .navigationTitle(workout.routineName.isEmpty ? "Workout" : workout.routineName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
