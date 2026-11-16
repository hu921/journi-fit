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

/// Shows a bundled photo (index 0 = start position), or a placeholder icon.
struct ExerciseImage: View {
    let exercise: Exercise
    var index = 0

    var body: some View {
        if exercise.images.indices.contains(index),
           let image = ExercisePhoto.load(exercise.images[index]) {
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

enum ExercisePhoto {
    private static let cache = NSCache<NSString, UIImage>()

    /// Photos ship in the app as <exerciseID>_<n>.jpg.
    static func load(_ name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        let url = Bundle.main.url(forResource: name, withExtension: "jpg")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "ExercisePhotos")
        guard let url, let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}
