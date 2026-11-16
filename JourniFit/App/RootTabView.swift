import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(RoutineImporter.self) private var importer
    @Environment(\.modelContext) private var context

    var body: some View {
        @Bindable var importer = importer
        TabView {
            RoutineListView()
                .tabItem { Label("Routines", systemImage: "list.bullet.clipboard") }
            MachineFinderView()
                .tabItem { Label("Finder", systemImage: "magnifyingglass") }
            MyGymView()
                .tabItem { Label("My Gym", systemImage: "dumbbell") }
            GoalListView()
                .tabItem { Label("Goals", systemImage: "target") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .sheet(item: $importer.pending) { shared in
            ImportRoutineView(shared: shared) {
                shared.insert(into: context)
                importer.pending = nil
            } onCancel: {
                importer.pending = nil
            }
        }
        .alert("Could not open routine", isPresented: $importer.showError) {
            Button("OK", role: .cancel) {}
        }
    }
}
