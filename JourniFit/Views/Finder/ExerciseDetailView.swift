import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var myMachines: [GymMachine]
    let exercise: Exercise
    @State private var showAddToRoutine = false
    @State private var addedTo: String?

    private var isInMyGym: Bool {
        myMachines.contains { $0.exerciseID == exercise.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Start and end position photos
                TabView {
                    ForEach(0..<max(exercise.images.count, 1), id: \.self) { i in
                        ExerciseImage(exercise: exercise, index: i)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if let machine = exercise.machine {
                    Label(machine, systemImage: "dumbbell.fill").font(.headline)
                }

                InfoRow(title: "Main muscles", value: exercise.primaryMuscles)
                if !exercise.secondaryMuscles.isEmpty {
                    InfoRow(title: "Also works", value: exercise.secondaryMuscles)
                }
                InfoRow(title: "Equipment", value: [exercise.equipmentLabel], capitalize: false)
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

                SimilarExercisesSection(exercise: exercise, myMachines: myMachines)
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    showAddToRoutine = true
                } label: {
                    Label("Add to routine", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    if !isInMyGym { context.insert(GymMachine(exerciseID: exercise.id)) }
                } label: {
                    Label(isInMyGym ? "In My Gym" : "My Gym",
                          systemImage: isInMyGym ? "checkmark.circle.fill" : "dumbbell")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isInMyGym)
            }
            .controlSize(.large)
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $showAddToRoutine) {
            AddToRoutineView(exercise: exercise) { routine in
                addedTo = routine.name
            }
        }
        .alert("Added to \(addedTo ?? "")", isPresented: Binding(
            get: { addedTo != nil }, set: { if !$0 { addedTo = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: [String]
    var capitalize = true

    var body: some View {
        HStack {
            Text(title).foregroundStyle(Theme.muted)
            Spacer()
            Text((capitalize ? value.map(\.capitalized) : value).joined(separator: ", "))
        }
    }
}

/// Substitutes: exercises for the same muscle. Ones in My Gym come first.
private struct SimilarExercisesSection: View {
    let exercise: Exercise
    let myMachines: [GymMachine]

    private var items: [Exercise] {
        let mine = Set(myMachines.map(\.exerciseID))
        return ExerciseLibrary.shared.similar(to: exercise, limit: 12)
            .sorted { (mine.contains($0.id) ? 1 : 0) > (mine.contains($1.id) ? 1 : 0) }
            .prefix(6).map { $0 }
    }

    var body: some View {
        if !items.isEmpty {
            Text("Similar exercises").font(.title3.bold()).padding(.top, 8)
            Text("Use one of these if this machine is busy or missing.")
                .font(.footnote).foregroundStyle(Theme.muted)
            ForEach(items) { ex in
                NavigationLink {
                    ExerciseDetailView(exercise: ex)
                } label: {
                    HStack {
                        ExerciseRow(exercise: ex)
                        Spacer()
                        if myMachines.contains(where: { $0.exerciseID == ex.id }) {
                            Text("In My Gym").font(.caption2.bold()).foregroundStyle(Theme.success)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
