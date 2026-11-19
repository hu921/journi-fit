import SwiftUI
import SwiftData

// Shared search pieces for "Add exercise" and Finder:
// sort options, saved muscle/equipment filters, usage counts, and sectioned results.

enum ExerciseSort: String, CaseIterable, Identifiable {
    /// Your most used first, then the popular list, then A–Z.
    case recommended
    case alphabetical
    case mostUsed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recommended: return "Recommended"
        case .alphabetical: return "A–Z"
        case .mostUsed: return "Most used"
        }
    }

    var icon: String {
        switch self {
        case .recommended: return "star"
        case .alphabetical: return "textformat"
        case .mostUsed: return "flame"
        }
    }
}

struct ExerciseSection: Identifiable {
    let title: String
    let exercises: [Exercise]
    var id: String { title }
}

enum ExerciseUsage {
    /// Times each exercise was done: one count per workout with at least one completed set.
    static func counts(_ items: [WorkoutExercise]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for item in items where item.sortedSets.contains(where: \.done) {
            counts[item.exerciseID, default: 0] += 1
        }
        return counts
    }
}

enum ExerciseSections {
    /// How many "most used" exercises show above the popular list.
    static let mostUsedLimit = 10

    static func make(_ results: [Exercise], sort: ExerciseSort, usage: [String: Int]) -> [ExerciseSection] {
        let byName: (Exercise, Exercise) -> Bool = {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        let byUsage: (Exercise, Exercise) -> Bool = {
            let a = usage[$0.id] ?? 0, b = usage[$1.id] ?? 0
            return a != b ? a > b : byName($0, $1)
        }
        let used = results.filter { (usage[$0.id] ?? 0) > 0 }.sorted(by: byUsage)

        switch sort {
        case .alphabetical:
            return [ExerciseSection(title: "All exercises", exercises: results.sorted(by: byName))]

        case .mostUsed:
            let usedIDs = Set(used.map(\.id))
            return [
                ExerciseSection(title: "Most used", exercises: used),
                ExerciseSection(title: "Not used yet",
                                exercises: results.filter { !usedIDs.contains($0.id) }.sorted(by: byName)),
            ].filter { !$0.exercises.isEmpty }

        case .recommended:
            let top = Array(used.prefix(mostUsedLimit))
            let topIDs = Set(top.map(\.id))
            let popular = results
                .filter { $0.popularRank != nil && !topIDs.contains($0.id) }
                .sorted { ($0.popularRank ?? .max) < ($1.popularRank ?? .max) }
            let shown = topIDs.union(popular.map(\.id))
            let rest = results.filter { !shown.contains($0.id) }.sorted(by: byName)
            return [
                ExerciseSection(title: "Your most used", exercises: top),
                ExerciseSection(title: "Popular", exercises: popular),
                ExerciseSection(title: "All exercises", exercises: rest),
            ].filter { !$0.exercises.isEmpty }
        }
    }
}

/// Saved search settings. Each screen passes its own key prefix, so Finder and
/// "Add exercise" remember their own choices.
struct ExerciseFilterStorage: DynamicProperty {
    @AppStorage private var sortRaw: String
    @AppStorage private var musclesRaw: String
    @AppStorage private var equipmentRaw: String

    init(_ prefix: String) {
        _sortRaw = AppStorage(wrappedValue: ExerciseSort.recommended.rawValue, "\(prefix).sort")
        _musclesRaw = AppStorage(wrappedValue: "", "\(prefix).muscles")
        _equipmentRaw = AppStorage(wrappedValue: "", "\(prefix).equipment")
    }

    var sort: Binding<ExerciseSort> {
        Binding(get: { ExerciseSort(rawValue: sortRaw) ?? .recommended },
                set: { sortRaw = $0.rawValue })
    }

    var muscles: Binding<Set<String>> { Self.set($musclesRaw) }
    var equipment: Binding<Set<String>> { Self.set($equipmentRaw) }

    private static func set(_ raw: Binding<String>) -> Binding<Set<String>> {
        Binding(get: { Set(raw.wrappedValue.split(separator: ",").map(String.init)) },
                set: { raw.wrappedValue = $0.sorted().joined(separator: ",") })
    }
}

/// Row of chips under the search field: Sort, Muscle, Equipment, Clear.
struct ExerciseFilterBar: View {
    @Binding var sort: ExerciseSort
    @Binding var muscles: Set<String>
    @Binding var equipment: Set<String>

    private let library = ExerciseLibrary.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(ExerciseSort.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                } label: {
                    chip(sort.title, icon: "arrow.up.arrow.down", active: false)
                }

                Menu {
                    multiSelect(library.muscles, selection: $muscles, label: { $0.capitalized })
                } label: {
                    chip(title("Muscle", muscles, label: { $0.capitalized }),
                         icon: "figure.strengthtraining.traditional", active: !muscles.isEmpty)
                }
                .menuActionDismissBehavior(.disabled)

                Menu {
                    multiSelect(library.equipment, selection: $equipment, label: Exercise.label(forEquipment:))
                } label: {
                    chip(title("Equipment", equipment, label: Exercise.label(forEquipment:)),
                         icon: "dumbbell", active: !equipment.isEmpty)
                }
                .menuActionDismissBehavior(.disabled)

                if !muscles.isEmpty || !equipment.isEmpty {
                    Button("Clear") {
                        muscles = []
                        equipment = []
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func multiSelect(_ options: [String], selection: Binding<Set<String>>,
                             label: @escaping (String) -> String) -> some View {
        if !selection.wrappedValue.isEmpty {
            Button("Any", systemImage: "xmark.circle") { selection.wrappedValue = [] }
            Divider()
        }
        ForEach(options, id: \.self) { option in
            Toggle(label(option), isOn: Binding(
                get: { selection.wrappedValue.contains(option) },
                set: { on in
                    if on { selection.wrappedValue.insert(option) }
                    else { selection.wrappedValue.remove(option) }
                }))
        }
    }

    private func title(_ name: String, _ selected: Set<String>, label: (String) -> String) -> String {
        switch selected.count {
        case 0: return name
        case 1: return label(selected.first!)
        default: return "\(name) (\(selected.count))"
        }
    }

    private func chip(_ text: String, icon: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text).lineLimit(1)
            Image(systemName: "chevron.down").font(.caption2)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(active ? Color.white : Theme.text)
        .background(active ? Theme.primary : Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.muted.opacity(active ? 0 : 0.3)))
    }
}

/// Sectioned exercise list. `row` builds each row (a button or a navigation link).
struct ExerciseSectionsList<Row: View>: View {
    let sections: [ExerciseSection]
    var header: AnyView? = nil
    @ViewBuilder let row: (Exercise) -> Row

    var body: some View {
        List {
            if let header { header }
            if sections.isEmpty {
                Text("No exercises match. Try fewer filters.")
                    .foregroundStyle(Theme.muted)
            }
            ForEach(sections) { section in
                Section(section.title == "All exercises" && sections.count == 1
                        ? "\(section.exercises.count) exercises"
                        : section.title) {
                    ForEach(section.exercises) { row($0) }
                }
            }
        }
    }
}
