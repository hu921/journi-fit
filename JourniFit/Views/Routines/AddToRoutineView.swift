import SwiftUI
import SwiftData

/// Pick a routine (or make a new one) and add an exercise to it with 3 sets.
struct AddToRoutineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @State private var newName = ""
    let exercise: Exercise
    var onAdded: (Routine) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            List {
                Section("New routine") {
                    HStack {
                        TextField("Name", text: $newName)
                        Button("Create") {
                            let name = newName.trimmingCharacters(in: .whitespaces)
                            let routine = Routine(name: name.isEmpty ? "New routine" : name)
                            context.insert(routine)
                            add(to: routine)
                        }
                    }
                }
                if !routines.isEmpty {
                    Section("My routines") {
                        ForEach(routines) { routine in
                            Button { add(to: routine) } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(routine.name).foregroundStyle(Theme.text)
                                        Text("\(routine.items?.count ?? 0) exercises")
                                            .font(.caption).foregroundStyle(Theme.muted)
                                    }
                                    Spacer()
                                    if contains(routine) {
                                        Text("Already added").font(.caption).foregroundStyle(Theme.muted)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func contains(_ routine: Routine) -> Bool {
        (routine.items ?? []).contains { $0.exerciseID == exercise.id }
    }

    private func add(to routine: Routine) {
        routine.addExercise(exercise.id, in: context)
        onAdded(routine)
        dismiss()
    }
}

extension Routine {
    /// Adds an exercise at the end with 3 starting sets.
    func addExercise(_ exerciseID: String, in context: ModelContext) {
        let item = RoutineExercise(exerciseID: exerciseID, order: items?.count ?? 0)
        item.routine = self
        context.insert(item)
        for i in 0..<3 {
            let set = RoutineSet(order: i)
            set.routineExercise = item
            context.insert(set)
        }
    }
}
