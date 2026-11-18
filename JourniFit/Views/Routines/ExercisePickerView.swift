import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var done: [WorkoutExercise]
    @State private var search = ""
    private var filters = ExerciseFilterStorage("exercisePicker")
    let onPick: (Exercise) -> Void

    init(onPick: @escaping (Exercise) -> Void) {
        self.onPick = onPick
    }

    private var sections: [ExerciseSection] {
        let results = ExerciseLibrary.shared.search(
            text: search, muscles: filters.muscles.wrappedValue, equipment: filters.equipment.wrappedValue)
        return ExerciseSections.make(results, sort: filters.sort.wrappedValue,
                                     usage: ExerciseUsage.counts(done))
    }

    var body: some View {
        NavigationStack {
            ExerciseSectionsList(sections: sections) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .buttonStyle(.plain)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ExerciseFilterBar(sort: filters.sort, muscles: filters.muscles, equipment: filters.equipment)
                    .background(.bar)
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Exercise, muscle, or machine")
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
