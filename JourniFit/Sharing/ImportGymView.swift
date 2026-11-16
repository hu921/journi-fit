import SwiftUI
import SwiftData

struct ImportGymView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [GymProfile]
    @Query private var existing: [GymMachine]
    let gym: SharedGym
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if !gym.location.isEmpty {
                    Section { Label(gym.location, systemImage: "mappin.and.ellipse") }
                }
                Section("\(gym.machines.count) machines") {
                    ForEach(Array(gym.machines.enumerated()), id: \.offset) { _, m in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name(of: m))
                            if !m.settings.isEmpty {
                                Text(m.settings).font(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                }
                Section {
                    Text("New machines are added to My Gym. Machines you already have are kept as they are.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
            }
            .navigationTitle(gym.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onDone) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to My Gym") {
                        gym.merge(into: context, profile: profiles.first, existing: existing)
                        onDone()
                    }
                }
            }
        }
    }

    private func name(of m: SharedGym.Machine) -> String {
        if !m.nickname.isEmpty { return m.nickname }
        return ExerciseLibrary.shared.exercise(id: m.exerciseID)?.name
            ?? (m.customName.isEmpty ? "Machine" : m.customName)
    }
}
