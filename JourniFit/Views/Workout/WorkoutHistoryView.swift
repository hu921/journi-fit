import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]

    private var totalTime: TimeInterval { workouts.reduce(0) { $0 + $1.duration } }

    var body: some View {
        List {
            if !workouts.isEmpty {
                Section {
                    LabeledContent("Workouts", value: "\(workouts.count)")
                    LabeledContent("Total time", value: totalTime.shortString)
                }
            }
            Section {
                ForEach(workouts) { w in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.routineName.isEmpty ? "Workout" : w.routineName).font(.headline)
                        Text("\(w.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(w.duration.clockString) · \(w.completedSets) sets")
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                }
                .onDelete { offsets in
                    offsets.map { workouts[$0] }.forEach(context.delete)
                }
            }
        }
        .overlay {
            if workouts.isEmpty {
                ContentUnavailableView("No workouts yet", systemImage: "clock",
                                       description: Text("Start a routine to log a workout."))
            }
        }
        .navigationTitle("Workout history")
    }
}
