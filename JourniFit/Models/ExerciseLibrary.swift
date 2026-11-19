import Foundation

/// Loads the exercise database that ships inside the app. No network.
final class ExerciseLibrary {
    static let shared = ExerciseLibrary()

    let exercises: [Exercise]
    private let byID: [String: Exercise]

    init(bundle: Bundle = .main) {
        var loaded: [Exercise] = []
        // exercises.json: Free Exercise DB. extra_exercises.json: ones it lacks (scripts/hevy_names.py).
        for file in ["exercises", "extra_exercises"] {
            if let url = bundle.url(forResource: file, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let list = try? JSONDecoder().decode([Exercise].self, from: data) {
                loaded += list
            }
        }
        loaded.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        exercises = loaded
        byID = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func exercise(id: String) -> Exercise? { byID[id] }

    var muscles: [String] {
        Array(Set(exercises.flatMap(\.allMuscles))).sorted()
    }

    var equipment: [String] {
        Array(Set(exercises.map(\.equipment)))
            .sorted { Exercise.label(forEquipment: $0) < Exercise.label(forEquipment: $1) }
    }

    /// Search by exercise name (new or original), machine name, muscle, or equipment.
    /// Every word must match, in any order ("bench press barbell" finds "Bench Press (Barbell)").
    /// Empty muscle or equipment sets mean "any".
    func search(text: String, muscles: Set<String> = [], equipment: Set<String> = [],
                machinesOnly: Bool = false) -> [Exercise] {
        let words = Self.words(text)
        return exercises.filter { ex in
            if machinesOnly && ex.machine == nil { return false }
            if !muscles.isEmpty && muscles.isDisjoint(with: ex.primaryMuscles) { return false }
            if !equipment.isEmpty && !equipment.contains(ex.equipment) { return false }
            guard !words.isEmpty else { return true }
            let haystack = ([ex.name, ex.originalName ?? "", ex.equipment, ex.equipmentLabel,
                             ex.machine ?? ""] + ex.allMuscles)
                .joined(separator: " ")
                .lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }
    }

    /// Splits search text into lowercase words. "(" and "," are ignored so pasted names still match.
    static func words(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { $0.isWhitespace || "-(),".contains($0) })
            .map(String.init)
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
