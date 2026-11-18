import SwiftUI
import SwiftData

/// The running workout: total time, sets to check off, and a rest timer.
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: Workout
    @State private var restEndsAt: Date?
    @State private var showFinish = false
    @State private var showUpdateRoutine = false
    @State private var showDiscard = false
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 24) {
                        Stat(title: "Time") {
                            TimelineView(.periodic(from: workout.startedAt, by: 1)) { _ in
                                Text(workout.duration.clockString).monospacedDigit()
                            }
                        }
                        Stat(title: "Sets") { Text("\(workout.completedSets)") }
                        Stat(title: "Volume") { Text(workout.volume.formatted(.number.precision(.fractionLength(0)))) }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                ForEach(workout.sortedExercises) { item in
                    WorkoutExerciseSection(item: item) { rest in
                        restEndsAt = rest > 0 ? .now.addingTimeInterval(TimeInterval(rest)) : nil
                    }
                }

                Section {
                    Button { showPicker = true } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button("Discard workout", role: .destructive) { showDiscard = true }
                }
            }
            .navigationTitle(workout.routineName.isEmpty ? "Workout" : workout.routineName)
            .keyboardDoneButton()
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if let restEndsAt {
                    RestBanner(endsAt: restEndsAt) { self.restEndsAt = $0 }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        // Exercises changed? Ask whether to update the routine.
                        if let routine = workout.sourceRoutine(in: context),
                           workout.changedPlan(comparedTo: routine) {
                            showUpdateRoutine = true
                        } else {
                            showFinish = true
                        }
                    }
                        .bold()
                }
            }
            .confirmationDialog("Finish workout?", isPresented: $showFinish, titleVisibility: .visible) {
                Button("Finish") { workout.endedAt = .now }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("Total time \(workout.duration.clockString). \(workout.completedSets) sets done.")
            }
            .confirmationDialog("Update \(workout.routineName.isEmpty ? "routine" : workout.routineName)?",
                                isPresented: $showUpdateRoutine, titleVisibility: .visible) {
                Button("Update routine") {
                    if let routine = workout.sourceRoutine(in: context) {
                        workout.updateRoutine(routine, in: context)
                    }
                    workout.endedAt = .now
                }
                Button("Keep original routine") { workout.endedAt = .now }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("You changed exercises, sets or rest in this workout. Save these changes to the routine for next time?")
            }
            .confirmationDialog("Discard this workout?", isPresented: $showDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { context.delete(workout) }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { exercise in
                    let we = WorkoutExercise(exerciseID: exercise.id,
                                             order: workout.exercises?.count ?? 0, restSeconds: 90)
                    we.workout = workout
                    context.insert(we)
                    let last = LastPerformance.sets(for: exercise.id, in: context)
                    let blank: [LastPerformance.SetValues] = [(weight: 0, reps: 10)]
                    for (i, v) in (last ?? blank).enumerated() {
                        let ws = WorkoutSet(order: i, weight: v.weight, reps: v.reps)
                        if last != nil { ws.previousWeight = v.weight; ws.previousReps = v.reps }
                        ws.workoutExercise = we
                        context.insert(ws)
                    }
                }
            }
        }
    }
}

private struct Stat<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 2) {
            content.font(.title2.bold()).foregroundStyle(Theme.primary)
            Text(title).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

private struct WorkoutExerciseSection: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: WorkoutExercise
    let onSetDone: (Int) -> Void
    @State private var collapsed = false
    @State private var showReplace = false

    var body: some View {
        Section {
            if collapsed {
                let done = item.sortedSets.filter(\.done).count
                Text("\(done) of \(item.sortedSets.count) sets done")
                    .font(.subheadline).foregroundStyle(Theme.muted)
            } else {
            RestPicker(seconds: $item.restSeconds)

            HStack {
                Text("SET").frame(width: 32, alignment: .leading)
                Text("LAST").frame(width: 70)
                Text("WEIGHT").frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
                Image(systemName: "checkmark").frame(width: 36)
            }
            .font(.caption.bold())
            .foregroundStyle(Theme.muted)

            ForEach(Array(item.sortedSets.enumerated()), id: \.element.id) { index, set in
                WorkoutSetRow(number: index + 1, set: set) {
                    if set.done { onSetDone(item.restSeconds) }
                }
            }
            .onDelete { offsets in
                let sets = item.sortedSets
                offsets.map { sets[$0] }.forEach(context.delete)
            }

            Button {
                let last = item.sortedSets.last
                let s = WorkoutSet(order: item.sets?.count ?? 0,
                                   weight: last?.weight ?? 0, reps: last?.reps ?? 10)
                s.workoutExercise = item
                context.insert(s)
            } label: {
                Label("Add set", systemImage: "plus")
            }
            }
        } header: {
            HStack(spacing: 10) {
                // Tap the title to collapse or expand this exercise.
                Button {
                    withAnimation { collapsed.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        if let exercise = item.exercise {
                            ExerciseImage(exercise: exercise)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        }
                        Text(item.exercise?.name ?? "Exercise")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                            .textCase(nil)
                            .multilineTextAlignment(.leading)
                        Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.muted)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Menu {
                    Button("Replace exercise", systemImage: "arrow.triangle.2.circlepath") { showReplace = true }
                    Button("Remove exercise", systemImage: "trash", role: .destructive) {
                        context.delete(item)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .sheet(isPresented: $showReplace) {
                ExercisePickerView { exercise in replace(with: exercise.id) }
            }
        }
    }

    /// Swap in another exercise mid-workout. Keeps the sets; fills weight
    /// and reps from last time for the new exercise when there is history.
    private func replace(with exerciseID: String) {
        item.exerciseID = exerciseID
        let last = LastPerformance.sets(for: exerciseID, in: context)
        for (i, set) in item.sortedSets.enumerated() {
            let v: LastPerformance.SetValues? = last.map { i < $0.count ? $0[i] : $0[$0.count - 1] }
            set.previousWeight = v?.weight
            set.previousReps = v?.reps
            if let v, !set.done {
                set.weight = v.weight
                set.reps = v.reps
            }
        }
    }
}

private struct WorkoutSetRow: View {
    let number: Int
    @Bindable var set: WorkoutSet
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Text("\(number)").font(.body.bold()).frame(width: 32, alignment: .leading)
            Group {
                if let w = set.previousWeight, let r = set.previousReps {
                    Text("\(w.formatted()) × \(r)")
                } else {
                    Text("–")
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: 70)
            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Button {
                set.done.toggle()
                onToggle()
            } label: {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.done ? Theme.success : Theme.muted)
            }
            .buttonStyle(.plain)
            .frame(width: 36)
        }
        .listRowBackground(set.done ? Theme.success.opacity(0.12) : nil)
    }
}

/// Counts down rest time after a set is checked.
private struct RestBanner: View {
    let endsAt: Date
    let onChange: (Date?) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let left = endsAt.timeIntervalSince(context.date)
            HStack {
                Label(left > 0 ? "Rest \(left.clockString)" : "Rest done",
                      systemImage: "timer")
                    .font(.headline.monospacedDigit())
                Spacer()
                Button("+15s") { onChange(endsAt.addingTimeInterval(15)) }
                    .buttonStyle(.bordered)
                Button("Skip") { onChange(nil) }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.bar)
        }
    }
}
