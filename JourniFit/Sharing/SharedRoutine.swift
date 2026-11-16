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
    struct Item: Codable {
        var exerciseID: String
        var sets: Int
        var reps: Int
        var restSeconds: Int
    }

    var formatVersion = 1
    var name: String
    var notes: String
    var items: [Item]

    var id: String { name + "\(items.count)" }

    init(routine: Routine) {
        name = routine.name
        notes = routine.notes
        items = routine.sortedItems.map {
            Item(exerciseID: $0.exerciseID, sets: $0.sets, reps: $0.reps, restSeconds: $0.restSeconds)
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
                                     sets: item.sets, reps: item.reps, restSeconds: item.restSeconds)
            re.routine = routine
            context.insert(re)
        }
    }
}

/// Receives links and files opened from outside the app.
@Observable
final class RoutineImporter {
    var pending: SharedRoutine?
    var showError = false

    func handle(url: URL) {
        if let shared = SharedRoutine(link: url) ?? SharedRoutine(fileURL: url) {
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
