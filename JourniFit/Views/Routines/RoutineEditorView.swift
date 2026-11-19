import SwiftUI
import SwiftData

/// Routine builder: each exercise has its own list of sets and a rest time.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var routine: Routine
    @State private var showPicker = false
    @State private var showReorder = false

    var body: some View {
        List {
            Section {
                TextField("Routine name", text: $routine.name)
                    .font(.title3.bold())
                TextField("Notes", text: $routine.notes, axis: .vertical)
            }

            ForEach(routine.sortedItems) { item in
                ExerciseSetsSection(
                    item: item,
                    canReorder: routine.sortedItems.count > 1,
                    onReorder: { showReorder = true },
                    onRemove: { remove(item) }
                )
            }

            Section {
                Button { showPicker = true } label: {
                    Label("Add exercise", systemImage: "plus.circle.fill")
                }
                if routine.sortedItems.count > 1 {
                    Button { showReorder = true } label: {
                        Label("Change order", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        // Start Routine sits at the bottom, and only once the routine has exercises.
        .safeAreaInset(edge: .bottom) {
            if !routine.sortedItems.isEmpty {
                StartRoutineButton(routine: routine)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
            }
        }
        .navigationTitle(routine.name.isEmpty ? "Routine" : routine.name)
        .keyboardDoneButton()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { ShareRoutineMenu(routine: routine) }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerView { exercise in
                routine.addExercise(exercise.id, in: context)
            }
        }
        .sheet(isPresented: $showReorder) {
            ReorderExercisesSheet(routine: routine)
        }
    }

    private func remove(_ item: RoutineExercise) {
        context.delete(item)
        let rest = routine.sortedItems.filter { $0 != item }
        for (i, it) in rest.enumerated() { it.order = i }
    }
}

private struct ExerciseSetsSection: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: RoutineExercise
    let canReorder: Bool
    let onReorder: () -> Void
    let onRemove: () -> Void
    @State private var collapsed = false
    @State private var showReplace = false

    var body: some View {
        Section {
            if collapsed {
                Text(summary).font(.subheadline).foregroundStyle(Theme.muted)
            } else {
            if let last = LastPerformance.summary(for: item.exerciseID, in: context) {
                Label("Last time: \(last)", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            // Rest time for this exercise
            RestPicker(seconds: $item.restSeconds)

            // Column titles
            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text("WEIGHT").frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
            }
            .font(.caption.bold())
            .foregroundStyle(Theme.muted)

            ForEach(Array(item.sortedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(number: index + 1, set: set)
            }
            .onDelete(perform: deleteSets)

            Button { addSet() } label: {
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
                        Text(item.exercise?.name ?? "Unknown exercise")
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
                    Button("Change order", systemImage: "arrow.up.arrow.down", action: onReorder)
                        .disabled(!canReorder)
                    Button("Remove exercise", systemImage: "trash", role: .destructive, action: onRemove)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .sheet(isPresented: $showReplace) {
                ExercisePickerView { exercise in replace(with: exercise.id) }
            }
        }
    }

    private var summary: String {
        let sets = item.sortedSets
        guard let first = sets.first else { return "No sets" }
        return "\(sets.count) \(sets.count == 1 ? "set" : "sets") · \(first.weight.formatted()) × \(first.reps)"
    }

    /// Swap in another exercise. Keeps the number of sets; uses last time's
    /// weight and reps for the new exercise when there is history.
    private func replace(with exerciseID: String) {
        item.exerciseID = exerciseID
        guard let last = LastPerformance.sets(for: exerciseID, in: context) else { return }
        for (i, set) in item.sortedSets.enumerated() {
            let v = i < last.count ? last[i] : last[last.count - 1]
            set.weight = v.weight
            set.reps = v.reps
        }
    }

    /// New set copies the last set's weight and reps.
    private func addSet() {
        let last = item.sortedSets.last
        let set = RoutineSet(order: (item.sets?.count ?? 0),
                             weight: last?.weight ?? 0,
                             reps: last?.reps ?? 10)
        set.routineExercise = item
        context.insert(set)
    }

    private func deleteSets(_ offsets: IndexSet) {
        let sets = item.sortedSets
        offsets.map { sets[$0] }.forEach(context.delete)
        for (i, s) in item.sortedSets.filter({ !offsets.map { sets[$0] }.contains($0) }).enumerated() {
            s.order = i
        }
    }

}

private struct SetRow: View {
    let number: Int
    @Bindable var set: RoutineSet

    var body: some View {
        HStack {
            Text("\(number)")
                .font(.body.bold())
                .frame(width: 36, alignment: .leading)
            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct ShareRoutineMenu: View {
    let routine: Routine

    var body: some View {
        let shared = SharedRoutine(routine: routine)
        Menu {
            if let link = shared.link {
                ShareLink("Share as link", item: link)
            }
            ShareLink("Share as file", item: shared,
                      preview: SharePreview(routine.name.isEmpty ? "Routine" : routine.name))
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}

/// Drag exercises into a new order. Each row is compact so the whole routine fits.
private struct ReorderExercisesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let routine: Routine
    @State private var items: [RoutineExercise] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Theme.primary, in: Circle())
                            if let exercise = item.exercise {
                                ExerciseImage(exercise: exercise)
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.exercise?.name ?? "Unknown exercise")
                                    .font(.body)
                                    .foregroundStyle(Theme.text)
                                let count = item.sortedSets.count
                                Text("\(count) \(count == 1 ? "set" : "sets")")
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    .onMove { from, to in items.move(fromOffsets: from, toOffset: to) }
                } footer: {
                    Text("Hold the handle on the right and drag to change the order.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Change order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        for (i, item) in items.enumerated() { item.order = i }
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .onAppear { items = routine.sortedItems }
    }
}
