import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    let onPick: (Exercise) -> Void

    private var results: [Exercise] {
        ExerciseLibrary.shared.search(text: search, muscle: nil, equipment: nil, machinesOnly: false)
    }

    var body: some View {
        NavigationStack {
            List(results) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $search, prompt: "Exercise, muscle, or machine")
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
