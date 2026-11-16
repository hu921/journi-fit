import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { WorkoutHistoryView() } label: {
                    Label("Workout history", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink { DietNotesView() } label: {
                    Label("Diet notes", systemImage: "fork.knife")
                }
                NavigationLink { AboutView() } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("More")
        }
    }
}
