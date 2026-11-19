import SwiftUI
import SwiftData

/// Settings. Version 1 holds import only; more options come later.
struct SettingsView: View {
    @Environment(RoutineImporter.self) private var importer
    @State private var showImport = false
    @Environment(\.modelContext) private var context
    @State private var confirm: CleanUp?
    @State private var done: String?

    var body: some View {
        List {
            Section {
                Button { showImport = true } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Import a journi Fit routine or gym file, or workout history exported from another app (CSV). You can pick several files at once.")
            }

            // TEMPORARY: for testing only. Remove before the official App Store submit.
            Section {
                Button(role: .destructive) { confirm = .workouts } label: {
                    Label("Delete all workout history", systemImage: "calendar.badge.minus")
                }
                Button(role: .destructive) { confirm = .everything } label: {
                    Label("Delete all app data", systemImage: "trash")
                }
            } header: {
                Text("Data clean (testing)")
            } footer: {
                Text("Workout history: removes past workouts, streaks and breakthroughs. Routines stay. All app data: also removes routines, gyms, goals, diet notes and your profile. This cannot be undone.")
            }
        }
        .confirmationDialog(confirm?.title ?? "", isPresented: Binding(get: { confirm != nil },
                                                                     set: { if !$0 { confirm = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let confirm { clean(confirm) }
                confirm = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
        .alert("Done", isPresented: Binding(get: { done != nil }, set: { if !$0 { done = nil } })) {
            Button("OK") {}
        } message: {
            Text(done ?? "")
        }
        .navigationTitle("Settings")
        .fileImporter(isPresented: $showImport,
                      allowedContentTypes: [.journiFitRoutine, .journiFitGym, .commaSeparatedText, .plainText],
                      allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            // journi Fit share files open in their own preview; CSV files import workout history.
            let shareFiles = urls.filter { ["journifit", "journigym"].contains($0.pathExtension.lowercased()) }
            let csvFiles = urls.filter { !shareFiles.contains($0) }
            if let first = shareFiles.first { importer.handle(url: first) }
            if !csvFiles.isEmpty {
                done = WorkoutImporter.importFiles(csvFiles, into: context).message
            }
        }
    }

    private enum CleanUp {
        case workouts, everything
        var title: String {
            self == .workouts ? "Delete all workout history?" : "Delete all app data?"
        }
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        for item in (try? context.fetch(FetchDescriptor<T>())) ?? [] { context.delete(item) }
    }

    private func clean(_ what: CleanUp) {
        deleteAll(WorkoutSet.self)
        deleteAll(WorkoutExercise.self)
        deleteAll(Workout.self)
        if what == .everything {
            deleteAll(RoutineSet.self)
            deleteAll(RoutineExercise.self)
            deleteAll(Routine.self)
            deleteAll(GymMachine.self)
            deleteAll(GymProfile.self)
            deleteAll(GoalEntry.self)
            deleteAll(Goal.self)
            deleteAll(DietNote.self)
            deleteAll(UserProfile.self)
        }
        try? context.save()
        done = what == .workouts ? "Workout history deleted." : "All app data deleted."
    }
}
