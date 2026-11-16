import SwiftUI
import SwiftData

/// Routine builder: add exercises, set sets, reps, and rest.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var routine: Routine
    @State private var showPicker = false

    var body: some View {
        List {
            Section {
                TextField("Routine name", text: $routine.name)
                TextField("Notes", text: $routine.notes, axis: .vertical)
            }

            Section("Exercises") {
                ForEach(routine.sortedItems) { item in
                    RoutineItemRow(item: item)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)

                Button { showPicker = true } label: {
                    Label("Add exercise", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle(routine.name.isEmpty ? "Routine" : routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { ShareRoutineMenu(routine: routine) }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerView { exercise in
                let item = RoutineExercise(exerciseID: exercise.id, order: (routine.items?.count ?? 0))
                item.routine = routine
                context.insert(item)
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        let items = routine.sortedItems
        offsets.map { items[$0] }.forEach(context.delete)
        renumber()
    }

    private func move(_ from: IndexSet, _ to: Int) {
        var items = routine.sortedItems
        items.move(fromOffsets: from, toOffset: to)
        for (i, item) in items.enumerated() { item.order = i }
    }

    private func renumber() {
        for (i, item) in routine.sortedItems.enumerated() { item.order = i }
    }
}

private struct RoutineItemRow: View {
    @Bindable var item: RoutineExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.exercise?.name ?? "Unknown exercise").font(.headline)
            Stepper("Sets: \(item.sets)", value: $item.sets, in: 1...20)
            Stepper("Reps: \(item.reps)", value: $item.reps, in: 1...100)
            Stepper("Rest: \(item.restSeconds)s", value: $item.restSeconds, in: 0...600, step: 15)
        }
        .padding(.vertical, 4)
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
