import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(RoutineImporter.self) private var importer
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.endedAt == nil }, sort: \Workout.startedAt)
    private var activeWorkouts: [Workout]

    var body: some View {
        @Bindable var importer = importer
        TabView {
            RoutineListView()
                .tabItem { Label("Routines", systemImage: "list.bullet.clipboard") }
            WorkoutHistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            MyGymView()
                .tabItem { Label("My Gym", systemImage: "dumbbell") }
            StreakView()
                .tabItem { Label("Streak", systemImage: "flame") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .fullScreenCover(item: Binding(get: { activeWorkouts.first }, set: { _ in })) { workout in
            ActiveWorkoutView(workout: workout)
        }
        .sheet(item: $importer.pending) { shared in
            ImportRoutineView(shared: shared) {
                shared.insert(into: context)
                importer.pending = nil
            } onCancel: {
                importer.pending = nil
            }
        }
        .sheet(item: $importer.pendingGym) { gym in
            ImportGymView(gym: gym) {
                importer.pendingGym = nil
            }
        }
        .alert("Could not open this file or link", isPresented: $importer.showError) {
            Button("OK", role: .cancel) {}
        }
    }
}
