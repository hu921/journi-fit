import SwiftUI
import SwiftData

/// Routine builder: each exercise has its own list of sets and a rest time.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var routine: Routine
    @State private var showPicker = false

    var body: some View {
        List {
            Section {
                StartRoutineButton(routine: routine)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                TextField("Routine name", text: $routine.name)
                TextField("Notes", text: $routine.notes, axis: .vertical)
            }

            ForEach(routine.sortedItems) { item in
                ExerciseSetsSection(
                    item: item,
                    canMoveUp: item.order > 0,
                    canMoveDown: item.order < routine.sortedItems.count - 1,
                    onMove: { move(item, by: $0) },
                    onRemove: { remove(item) }
                )
            }

            Section {
                Button { showPicker = true } label: {
                    Label("Add exercise", systemImage: "plus.circle.fill")
                }
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
    }

    private func move(_ item: RoutineExercise, by offset: Int) {
        var items = routine.sortedItems
        guard let from = items.firstIndex(of: item) else { return }
        let to = from + offset
        guard items.indices.contains(to) else { return }
        items.swapAt(from, to)
        for (i, it) in items.enumerated() { it.order = i }
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
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMove: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        Section {
            if let last = LastPerformance.summary(for: item.exerciseID, in: context) {
                Label("Last time: \(last)", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            // Rest time for this exercise
            Picker(selection: $item.restSeconds) {
                ForEach(Array(stride(from: 0, through: 300, by: 15)), id: \.self) { s in
                    Text(s == 0 ? "Off" : Self.format(s)).tag(s)
                }
            } label: {
                Label("Rest", systemImage: "timer").foregroundStyle(Theme.primary)
            }

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
        } header: {
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
                Spacer()
                Menu {
                    Button("Move up", systemImage: "arrow.up") { onMove(-1) }.disabled(!canMoveUp)
                    Button("Move down", systemImage: "arrow.down") { onMove(1) }.disabled(!canMoveDown)
                    Button("Remove exercise", systemImage: "trash", role: .destructive, action: onRemove)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
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

    static func format(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)min" : "\(m)min \(s)s"
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
