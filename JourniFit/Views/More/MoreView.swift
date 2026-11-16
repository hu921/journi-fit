import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { GoalListContent() } label: {
                    Label("Goals", systemImage: "target")
                }
                NavigationLink { MachineFinderContent() } label: {
                    Label("Exercise & machine finder", systemImage: "magnifyingglass")
                }
                NavigationLink { DietNotesView() } label: {
                    Label("Diet notes", systemImage: "fork.knife")
                }
                NavigationLink { SettingsView() } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                NavigationLink { AboutView() } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("More")
        }
    }
}
