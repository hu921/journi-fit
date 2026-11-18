import SwiftUI
import SwiftData

/// Search the bundled exercise database by machine, muscle, or equipment.
struct MachineFinderView: View {
    var body: some View {
        NavigationStack {
            MachineFinderContent()
        }
    }
}

/// Finder screen without its own NavigationStack, so it can be pushed from More.
struct MachineFinderContent: View {
    @Query private var done: [WorkoutExercise]
    @State private var search = ""
    @AppStorage("finder.machinesOnly") private var machinesOnly = true
    private var filters = ExerciseFilterStorage("finder")

    private var sections: [ExerciseSection] {
        let results = ExerciseLibrary.shared.search(
            text: search, muscles: filters.muscles.wrappedValue,
            equipment: filters.equipment.wrappedValue, machinesOnly: machinesOnly)
        return ExerciseSections.make(results, sort: filters.sort.wrappedValue,
                                     usage: ExerciseUsage.counts(done))
    }

    var body: some View {
        ExerciseSectionsList(sections: sections,
                             header: AnyView(Toggle("Machines only", isOn: $machinesOnly))) { exercise in
            NavigationLink(value: exercise) { ExerciseRow(exercise: exercise) }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ExerciseFilterBar(sort: filters.sort, muscles: filters.muscles, equipment: filters.equipment)
                .background(.bar)
        }
        .searchable(text: $search, prompt: "Machine, exercise, or muscle")
        .navigationTitle("Finder")
        .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
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
                Text(exercise.machine ?? exercise.equipmentLabel)
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
