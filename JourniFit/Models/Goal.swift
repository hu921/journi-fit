import Foundation
import SwiftData

enum GoalTrack: String, CaseIterable, Identifiable, Codable {
    case strength = "Strength"
    case weightLoss = "Weight loss"
    case muscle = "Build muscle"
    case endurance = "Endurance"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .strength: "bolt.fill"
        case .weightLoss: "scalemass"
        case .muscle: "figure.strengthtraining.traditional"
        case .endurance: "figure.run"
        case .custom: "star"
        }
    }
}

@Model
final class Goal {
    var title: String = ""
    var trackRaw: String = GoalTrack.custom.rawValue
    var unit: String = ""
    var startValue: Double = 0
    var targetValue: Double = 0
    var createdAt: Date = Date.now
    @Relationship(deleteRule: .cascade, inverse: \GoalEntry.goal)
    var entries: [GoalEntry]? = []

    init(title: String, track: GoalTrack, unit: String, startValue: Double, targetValue: Double) {
        self.title = title
        self.trackRaw = track.rawValue
        self.unit = unit
        self.startValue = startValue
        self.targetValue = targetValue
    }

    var track: GoalTrack { GoalTrack(rawValue: trackRaw) ?? .custom }

    var sortedEntries: [GoalEntry] {
        (entries ?? []).sorted { $0.date < $1.date }
    }

    var currentValue: Double { sortedEntries.last?.value ?? startValue }

    /// 0...1 progress from start to target. Works for goals that go up or down.
    var progress: Double {
        let span = targetValue - startValue
        guard span != 0 else { return 1 }
        return min(max((currentValue - startValue) / span, 0), 1)
    }
}

@Model
final class GoalEntry {
    var date: Date = Date.now
    var value: Double = 0
    var goal: Goal?

    init(date: Date = .now, value: Double) {
        self.date = date
        self.value = value
    }
}
