import SwiftUI
import SwiftData

@main
struct JourniFitApp: App {
    @State private var importer = RoutineImporter()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(importer)
                .tint(Theme.primary)
                .onOpenURL { url in importer.handle(url: url) }
        }
        // Data stays on device. With the iCloud capability on, SwiftData
        // syncs this store to the user's private iCloud database (backup).
        .modelContainer(for: [
            Routine.self,
            RoutineExercise.self,
            RoutineSet.self,
            GymMachine.self,
            Goal.self,
            GoalEntry.self,
            DietNote.self
        ])
    }
}
