import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// A shared gym machine list (.journigym). Declared in Info.plist.
    static let journiFitGym = UTType(exportedAs: "com.journipod.journifit.gym")
}

/// A gym's machine list that members can share with each other.
/// Personal data (last weight, photos) is not included.
struct SharedGym: Codable, Identifiable, Transferable {
    struct Machine: Codable {
        var exerciseID: String
        var customName: String
        var customMuscle: String
        var nickname: String
        var settings: String
    }

    var formatVersion = 1
    var name: String
    var location: String
    var machines: [Machine]

    var id: String { name + location + "\(machines.count)" }

    init(profile: GymProfile?, machines: [GymMachine]) {
        name = profile?.name ?? ""
        location = profile?.location ?? ""
        self.machines = machines.map {
            Machine(exerciseID: $0.exerciseID, customName: $0.customName,
                    customMuscle: $0.customMuscle, nickname: $0.nickname, settings: $0.settings)
        }
    }

    var title: String { name.isEmpty ? "My Gym" : name }

    // MARK: Link: journifit://gym?d=<base64url JSON>

    var link: URL? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        var c = URLComponents()
        c.scheme = AppInfo.urlScheme
        c.host = "gym"
        c.queryItems = [URLQueryItem(name: "d", value: data.base64URLEncoded())]
        return c.url
    }

    init?(link url: URL) {
        guard url.scheme == AppInfo.urlScheme, url.host == "gym",
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "d" })?.value,
              let data = Data(base64URLEncoded: value),
              let decoded = try? JSONDecoder().decode(SharedGym.self, from: data)
        else { return nil }
        self = decoded
    }

    // MARK: File

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .journiFitGym)
            .suggestedFileName { $0.title }
    }

    init?(fileURL url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard url.pathExtension == "journigym",
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SharedGym.self, from: data)
        else { return nil }
        self = decoded
    }

    // MARK: Save

    /// Adds machines the user does not have yet. Sets the gym name if empty.
    func merge(into context: ModelContext, profile: GymProfile?, existing: [GymMachine]) {
        let gym = profile ?? {
            let p = GymProfile()
            context.insert(p)
            return p
        }()
        if gym.name.isEmpty { gym.name = name }
        if gym.location.isEmpty { gym.location = location }

        for m in machines {
            let duplicate = existing.contains {
                m.exerciseID.isEmpty
                    ? $0.customName.caseInsensitiveCompare(m.customName) == .orderedSame
                    : $0.exerciseID == m.exerciseID
            }
            guard !duplicate else { continue }
            context.insert(GymMachine(exerciseID: m.exerciseID, customName: m.customName,
                                      customMuscle: m.customMuscle, nickname: m.nickname,
                                      settings: m.settings))
        }
    }
}
