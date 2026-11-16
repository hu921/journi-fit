import Foundation

/// Loads the exercise database that ships inside the app. No network.
final class ExerciseLibrary {
    static let shared = ExerciseLibrary()

    let exercises: [Exercise]
    private let byID: [String: Exercise]

    init(bundle: Bundle = .main) {
        var loaded: [Exercise] = []
        if let url = bundle.url(forResource: "exercises", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([Exercise].self, from: data) {
            loaded = list.sorted { $0.name < $1.name }
        }
        exercises = loaded
        byID = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func exercise(id: String) -> Exercise? { byID[id] }

    var muscles: [String] {
        Array(Set(exercises.flatMap(\.allMuscles))).sorted()
    }

    var equipment: [String] {
        Array(Set(exercises.map(\.equipment))).sorted()
    }

    /// Search by exercise name, machine name, muscle, or equipment.
    func search(text: String, muscle: String?, equipment: String?, machinesOnly: Bool) -> [Exercise] {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        return exercises.filter { ex in
            if machinesOnly && ex.machine == nil { return false }
            if let muscle, !ex.allMuscles.contains(muscle) { return false }
            if let equipment, ex.equipment != equipment { return false }
            guard !query.isEmpty else { return true }
            let haystack = ([ex.name, ex.equipment, ex.machine ?? ""] + ex.allMuscles)
                .joined(separator: " ")
                .lowercased()
            return haystack.contains(query)
        }
    }
}
