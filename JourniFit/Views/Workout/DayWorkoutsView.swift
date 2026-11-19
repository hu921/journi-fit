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
/// Tap Edit to fix mistakes: start and end time, weight, reps, done, or remove a set.
struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: Workout
    @State private var editing = false

    private var endedAt: Binding<Date> {
        Binding(get: { workout.endedAt ?? workout.startedAt },
                set: { workout.endedAt = max($0, workout.startedAt) })
    }

    var body: some View {
        List {
            Section {
                if editing {
                    DatePicker("Started", selection: $workout.startedAt)
                    DatePicker("Finished", selection: endedAt, in: workout.startedAt...)
                } else {
                    LabeledContent("Started", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
                    if let end = workout.endedAt {
                        LabeledContent("Finished", value: end.formatted(date: .omitted, time: .shortened))
                    }
                }
                LabeledContent("Total time", value: workout.duration.clockString)
                LabeledContent("Sets done", value: "\(workout.completedSets)")
                LabeledContent("Volume", value: workout.volume.formatted(.number.precision(.fractionLength(0))))
            } footer: {
                if editing {
                    Text("Forgot to tap Finish? Change Finished to when you really stopped.")
                }
            }

            if !editing && !MuscleMapView.scores(for: workout).isEmpty {
                Section("Muscles worked") {
                    MuscleMapView(workout: workout)
                }
            }

            ForEach(workout.sortedExercises) { item in
                Section {
                    if editing {
                        HStack {
                            Text("SET").frame(width: 30, alignment: .leading)
                            Text("WEIGHT").frame(maxWidth: .infinity)
                            Text("REPS").frame(maxWidth: .infinity)
                            Image(systemName: "checkmark").frame(width: 36)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Theme.muted)
                    }
                    ForEach(Array(item.sortedSets.enumerated()), id: \.element.id) { i, set in
                        Group {
                        if editing {
                            EditableSetRow(number: i + 1, set: set)
                        } else {
                            HStack {
                                Text("\(i + 1)").bold().frame(width: 30, alignment: .leading)
                                Text(set.summary)
                                Spacer()
                                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(set.done ? Theme.success : Theme.muted)
                            }
                        }
                        }
                        .deleteDisabled(!editing)
                    }
                    .onDelete { offsets in
                        let sets = item.sortedSets
                        offsets.map { sets[$0] }.forEach(context.delete)
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
        .keyboardDoneButton()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(editing ? "Done" : "Edit") {
                    withAnimation { editing.toggle() }
                }
                .bold(editing)
            }
        }
    }
}

private struct EditableSetRow: View {
    let number: Int
    @Bindable var set: WorkoutSet

    var body: some View {
        HStack {
            Text("\(number)").bold().frame(width: 30, alignment: .leading)
            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Button { set.done.toggle() } label: {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.done ? Theme.success : Theme.muted)
            }
            .buttonStyle(.plain)
            .frame(width: 36)
        }
    }
}
