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
    /// Every word must match, in any order ("bench press barbell" finds "Barbell Bench Press").
    func search(text: String, muscle: String?, equipment: String?, machinesOnly: Bool) -> [Exercise] {
        let words = text.lowercased().split(whereSeparator: { $0.isWhitespace || $0 == "-" }).map(String.init)
        return exercises.filter { ex in
            if machinesOnly && ex.machine == nil { return false }
            if let muscle, !ex.allMuscles.contains(muscle) { return false }
            if let equipment, ex.equipment != equipment { return false }
            guard !words.isEmpty else { return true }
            let haystack = ([ex.name, ex.equipment, ex.machine ?? ""] + ex.allMuscles)
                .joined(separator: " ")
                .lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }
    }

    /// Exercises that work the same main muscle. Used as substitutes.
    /// Same equipment type and machines ranked first.
    func similar(to exercise: Exercise, limit: Int = 8) -> [Exercise] {
        let target = Set(exercise.primaryMuscles)
        return exercises
            .filter { $0.id != exercise.id && !target.isDisjoint(with: $0.primaryMuscles) }
            .sorted { score($0, exercise) > score($1, exercise) }
            .prefix(limit)
            .map { $0 }
    }

    private func score(_ candidate: Exercise, _ base: Exercise) -> Int {
        var s = 0
        if candidate.primaryMuscles == base.primaryMuscles { s += 4 }
        if candidate.equipment == base.equipment { s += 2 }
        if candidate.machine != nil { s += 1 }
        return s
    }
}
