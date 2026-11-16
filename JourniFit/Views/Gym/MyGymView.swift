import SwiftUI
import SwiftData

/// The machines at the user's own gym, with their personal settings.
struct MyGymView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GymMachine.addedAt) private var machines: [GymMachine]

    var body: some View {
        NavigationStack {
            Group {
                if machines.isEmpty {
                    ContentUnavailableView("Your gym is empty",
                                           systemImage: "dumbbell",
                                           description: Text("Find a machine in Finder and tap Add to My Gym."))
                } else {
                    List {
                        ForEach(machines) { machine in
                            NavigationLink {
                                GymMachineEditor(machine: machine)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(machine.nickname.isEmpty ? (machine.exercise?.name ?? "Machine") : machine.nickname)
                                        .font(.headline)
                                    if !machine.settings.isEmpty {
                                        Text(machine.settings).font(.caption).foregroundStyle(Theme.muted)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { machines[$0] }.forEach(context.delete)
                        }
                    }
                }
            }
            .navigationTitle("My Gym")
        }
    }
}

private struct GymMachineEditor: View {
    @Bindable var machine: GymMachine

    var body: some View {
        Form {
            if let exercise = machine.exercise {
                Section {
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                }
            }
            Section("My notes") {
                TextField("Name or spot (e.g. near the window)", text: $machine.nickname)
                TextField("Settings (seat height, pin…)", text: $machine.settings, axis: .vertical)
                HStack {
                    Text("Last weight")
                    Spacer()
                    TextField("0", value: $machine.lastWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
        }
        .navigationTitle(machine.exercise?.name ?? "Machine")
        .navigationBarTitleDisplayMode(.inline)
    }
}
