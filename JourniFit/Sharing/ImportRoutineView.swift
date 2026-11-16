import SwiftUI

struct ImportRoutineView: View {
    let shared: SharedRoutine
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if !shared.notes.isEmpty {
                    Section("Notes") { Text(shared.notes) }
                }
                Section("Exercises") {
                    ForEach(Array(shared.items.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading) {
                            Text(ExerciseLibrary.shared.exercise(id: item.exerciseID)?.name ?? "Unknown exercise")
                            Text("\(item.sets.count) sets · rest \(item.restSeconds)s")
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
            .navigationTitle(shared.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: onSave) }
            }
        }
    }
}
