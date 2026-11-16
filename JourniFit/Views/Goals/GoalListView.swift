import SwiftUI
import SwiftData

struct GoalListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    ContentUnavailableView("No goals yet",
                                           systemImage: "target",
                                           description: Text("Pick a goal track to start."))
                } else {
                    List {
                        ForEach(goals) { goal in
                            NavigationLink { GoalDetailView(goal: goal) } label: { GoalRow(goal: goal) }
                        }
                        .onDelete { offsets in
                            offsets.map { goals[$0] }.forEach(context.delete)
                        }
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                Button { showNew = true } label: { Label("New goal", systemImage: "plus") }
            }
            .sheet(isPresented: $showNew) { NewGoalView() }
        }
    }
}

private struct GoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(goal.title, systemImage: goal.track.icon).font(.headline)
            ProgressView(value: goal.progress)
                .tint(goal.progress >= 1 ? Theme.success : Theme.primary)
            Text("\(goal.currentValue.formatted()) / \(goal.targetValue.formatted()) \(goal.unit)")
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 4)
    }
}

private struct NewGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var track: GoalTrack = .strength
    @State private var title = ""
    @State private var unit = "kg"
    @State private var start: Double = 0
    @State private var target: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Picker("Track", selection: $track) {
                    ForEach(GoalTrack.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) }
                }
                TextField("Goal (e.g. Bench press 60 kg)", text: $title)
                TextField("Unit (kg, lb, km, min)", text: $unit)
                LabeledContent("Start") {
                    TextField("0", value: $start, format: .number).keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Target") {
                    TextField("0", value: $target, format: .number).keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            .navigationTitle("New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(Goal(title: title.isEmpty ? track.rawValue : title,
                                            track: track, unit: unit,
                                            startValue: start, targetValue: target))
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    let goal: Goal
    @State private var newValue: Double?

    var body: some View {
        List {
            Section {
                ProgressView(value: goal.progress) {
                    Text("\(Int(goal.progress * 100))% to target")
                }
                .tint(goal.progress >= 1 ? Theme.success : Theme.primary)
            }
            Section("Log progress") {
                HStack {
                    TextField("New value (\(goal.unit))", value: $newValue, format: .number)
                        .keyboardType(.decimalPad)
                    Button("Add") {
                        guard let v = newValue else { return }
                        let entry = GoalEntry(value: v)
                        entry.goal = goal
                        context.insert(entry)
                        newValue = nil
                    }
                    .disabled(newValue == nil)
                }
            }
            Section("History") {
                ForEach(goal.sortedEntries.reversed()) { entry in
                    LabeledContent(entry.date.formatted(date: .abbreviated, time: .omitted),
                                   value: "\(entry.value.formatted()) \(goal.unit)")
                }
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
