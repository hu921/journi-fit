import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// A shared routine file (.journifit). Declared in Info.plist.
    static let journiFitRoutine = UTType(exportedAs: "com.journipod.journifit.routine")
}

/// The portable form of a routine. Used for both share links and files.
/// No server: the whole routine travels inside the link or file.
struct SharedRoutine: Codable, Identifiable, Transferable {
    struct SetItem: Codable {
        var weight: Double
        var reps: Int
    }

    struct Item: Codable {
        var exerciseID: String
        var restSeconds: Int
        var sets: [SetItem]
    }

    var formatVersion = 2
    var name: String
    var notes: String
    var items: [Item]

    var id: String { name + "\(items.count)" }

    init(routine: Routine) {
        name = routine.name
        notes = routine.notes
        items = routine.sortedItems.map {
            Item(exerciseID: $0.exerciseID,
                 restSeconds: $0.restSeconds,
                 sets: $0.sortedSets.map { SetItem(weight: $0.weight, reps: $0.reps) })
        }
    }

    // MARK: Link

    /// journifit://routine?d=<base64url JSON>
    var link: URL? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        var c = URLComponents()
        c.scheme = AppInfo.urlScheme
        c.host = "routine"
        c.queryItems = [URLQueryItem(name: "d", value: data.base64URLEncoded())]
        return c.url
    }

    init?(link url: URL) {
        guard url.scheme == AppInfo.urlScheme, url.host == "routine",
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "d" })?.value,
              let data = Data(base64URLEncoded: value),
              let decoded = try? JSONDecoder().decode(SharedRoutine.self, from: data)
        else { return nil }
        self = decoded
    }

    // MARK: File

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .journiFitRoutine)
            .suggestedFileName { $0.name.isEmpty ? "Routine" : $0.name }
    }

    init?(fileURL url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SharedRoutine.self, from: data)
        else { return nil }
        self = decoded
    }

    // MARK: Save

    func insert(into context: ModelContext) {
        let routine = Routine(name: name, notes: notes)
        context.insert(routine)
        for (index, item) in items.enumerated()
        where ExerciseLibrary.shared.exercise(id: item.exerciseID) != nil {
            let re = RoutineExercise(exerciseID: item.exerciseID, order: index,
                                     restSeconds: item.restSeconds)
            re.routine = routine
            context.insert(re)
            for (setIndex, s) in item.sets.enumerated() {
                let set = RoutineSet(order: setIndex, weight: s.weight, reps: s.reps)
                set.routineExercise = re
                context.insert(set)
            }
        }
    }
}

/// Receives routine and gym links and files opened from outside the app.
@Observable
final class RoutineImporter {
    var pending: SharedRoutine?
    var pendingGym: SharedGym?
    var showError = false

    func handle(url: URL) {
        if let gym = SharedGym(link: url) ?? SharedGym(fileURL: url) {
            pendingGym = gym
        } else if let shared = SharedRoutine(link: url) ?? SharedRoutine(fileURL: url) {
            pending = shared
        } else {
            showError = true
        }
    }
}

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded s: String) {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b.count % 4 != 0 { b += "=" }
        self.init(base64Encoded: b)
    }
}
