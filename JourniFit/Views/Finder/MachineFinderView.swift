import SwiftUI

/// Search the bundled exercise database by machine, muscle, or equipment.
struct MachineFinderView: View {
    @State private var search = ""
    @State private var muscle: String?
    @State private var equipment: String?
    @State private var machinesOnly = true

    private let library = ExerciseLibrary.shared

    private var results: [Exercise] {
        library.search(text: search, muscle: muscle, equipment: equipment, machinesOnly: machinesOnly)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Machines only", isOn: $machinesOnly)
                    Picker("Muscle", selection: $muscle) {
                        Text("Any").tag(String?.none)
                        ForEach(library.muscles, id: \.self) { Text($0.capitalized).tag(String?.some($0)) }
                    }
                    Picker("Equipment", selection: $equipment) {
                        Text("Any").tag(String?.none)
                        ForEach(library.equipment, id: \.self) { Text($0.capitalized).tag(String?.some($0)) }
                    }
                }

                Section("\(results.count) results") {
                    ForEach(results) { exercise in
                        NavigationLink(value: exercise) { ExerciseRow(exercise: exercise) }
                    }
                }
            }
            .searchable(text: $search, prompt: "Machine, exercise, or muscle")
            .navigationTitle("Machine Finder")
            .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ExerciseImage(exercise: exercise)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.body)
                Text(exercise.machine ?? exercise.equipment.capitalized)
                    .font(.caption).foregroundStyle(Theme.muted)
                Text(exercise.primaryMuscles.map(\.capitalized).joined(separator: ", "))
                    .font(.caption2).foregroundStyle(Theme.primary)
            }
        }
    }
}

/// Shows the first bundled photo, or a placeholder icon.
struct ExerciseImage: View {
    let exercise: Exercise

    var body: some View {
        if let name = exercise.images.first, let image = UIImage(named: name) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Theme.primary.opacity(0.15)
                Image(systemName: exercise.machine == nil ? "figure.strengthtraining.functional" : "dumbbell.fill")
                    .foregroundStyle(Theme.primary)
            }
        }
    }
}
