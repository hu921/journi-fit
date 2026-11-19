import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { MyGymContent() } label: {
                    Label("My Gym", systemImage: "dumbbell")
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
