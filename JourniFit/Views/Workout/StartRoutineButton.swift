import SwiftUI
import SwiftData

/// Starts a workout from a routine. Only one workout can run at a time.
struct StartRoutineButton: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }) private var active: [Workout]
    let routine: Routine
    @State private var showBusy = false

    var body: some View {
        Button {
            if active.isEmpty {
                _ = Workout.start(from: routine, in: context)
            } else {
                showBusy = true
            }
        } label: {
            Label("Start Routine", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(routine.items?.isEmpty ?? true)
        .alert("A workout is already running", isPresented: $showBusy) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Finish or discard it first.")
        }
    }
}
