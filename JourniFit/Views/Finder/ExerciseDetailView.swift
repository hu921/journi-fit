import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var myMachines: [GymMachine]
    let exercise: Exercise

    private var isInMyGym: Bool {
        myMachines.contains { $0.exerciseID == exercise.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ExerciseImage(exercise: exercise)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if let machine = exercise.machine {
                    Label(machine, systemImage: "dumbbell.fill").font(.headline)
                }

                InfoRow(title: "Main muscles", value: exercise.primaryMuscles)
                if !exercise.secondaryMuscles.isEmpty {
                    InfoRow(title: "Also works", value: exercise.secondaryMuscles)
                }
                InfoRow(title: "Equipment", value: [exercise.equipment])
                InfoRow(title: "Level", value: [exercise.level])

                Text("How to").font(.title3.bold())
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .frame(width: 22, height: 22)
                            .background(Theme.secondary, in: Circle())
                        Text(step)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !isInMyGym { context.insert(GymMachine(exerciseID: exercise.id)) }
                } label: {
                    Label(isInMyGym ? "In My Gym" : "Add to My Gym",
                          systemImage: isInMyGym ? "checkmark.circle.fill" : "plus.circle")
                }
                .disabled(isInMyGym)
            }
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: [String]

    var body: some View {
        HStack {
            Text(title).foregroundStyle(Theme.muted)
            Spacer()
            Text(value.map(\.capitalized).joined(separator: ", "))
        }
    }
}
