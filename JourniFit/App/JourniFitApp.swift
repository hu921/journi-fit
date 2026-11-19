import SwiftUI
import SwiftData
import CoreData

@main
struct JourniFitApp: App {
    @State private var importer = RoutineImporter()
    let container: ModelContainer

    static let models: [any PersistentModel.Type] = [
        UserProfile.self,
        Routine.self,
        RoutineExercise.self,
        RoutineSet.self,
        Workout.self,
        WorkoutExercise.self,
        WorkoutSet.self,
        GymProfile.self,
        GymMachine.self,
        Goal.self,
        GoalEntry.self,
        DietNote.self
    ]

    init() {
        // Data stays on device. With the iCloud capability on, SwiftData
        // syncs this store to the user's private iCloud database (backup).
        let config = ModelConfiguration()
        #if DEBUG
        CloudKitSchema.initializeIfNeeded(url: config.url, models: Self.models)
        #endif
        do {
            container = try ModelContainer(for: Schema(Self.models), configurations: config)
        } catch {
            fatalError("Could not open data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(importer)
                .tint(Theme.primary)
                .onOpenURL { url in importer.handle(url: url) }
        }
        .modelContainer(container)
    }
}

#if DEBUG
/// Debug builds only (run from Xcode): pushes every record type and field to the
/// CloudKit Development environment, so "Deploy Schema Changes" covers the whole model,
/// even types with no data yet (e.g. Goals) and fields that are still empty.
/// Runs once per `version`. Bump `version` whenever a @Model changes, then run from
/// Xcode once (signed in to iCloud) and deploy to Production again.
enum CloudKitSchema {
    static let version = 1
    static let containerID = "iCloud.com.journipod.journifit"

    static func initializeIfNeeded(url: URL, models: [any PersistentModel.Type]) {
        let key = "cloudKitSchemaVersion"
        guard UserDefaults.standard.integer(forKey: key) < version else { return }
        autoreleasepool {
            let desc = NSPersistentStoreDescription(url: url)
            desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerID)
            desc.shouldAddStoreAsynchronously = false
            guard let mom = NSManagedObjectModel.makeManagedObjectModel(for: models) else { return }
            let container = NSPersistentCloudKitContainer(name: "JourniFit", managedObjectModel: mom)
            container.persistentStoreDescriptions = [desc]
            var loadError: Error?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError {
                print("CloudKit schema: store failed to load: \(loadError)")
                return
            }
            do {
                try container.initializeCloudKitSchema()
                UserDefaults.standard.set(version, forKey: key)
                print("CloudKit schema: initialized (version \(version))")
            } catch {
                print("CloudKit schema: failed (signed in to iCloud?): \(error)")
            }
            if let store = container.persistentStoreCoordinator.persistentStores.first {
                try? container.persistentStoreCoordinator.remove(store)
            }
        }
    }
}
#endif
