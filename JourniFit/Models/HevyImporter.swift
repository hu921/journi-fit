import Foundation
import SwiftData

/// Imports a Hevy CSV export (Settings > Import from Hevy).
///
/// workout_data.csv: one row per set. We keep the workout title, start and end time,
/// exercise, and each set's weight and reps (warm-up sets included).
/// Timed or distance sets (Warm Up, Plank, Treadmill) keep their time and distance.
/// Skipped: notes, RPE and supersets.
///
/// measurement_data.csv: only the latest body weight goes into Profile.
///
/// Exercise names are matched to our library: Resources/hevy_names.json first
/// (built by scripts/hevy_names.py), then the same name ignoring case and punctuation.
/// Exercises we can't match are skipped and listed in the result.
enum HevyImporter {
    struct Result {
        var workouts = 0
        var sets = 0
        var duplicates = 0
        var bodyWeight: Double?
        var unmatched: Set<String> = []
        var unknownFile = false

        var message: String {
            var lines: [String] = []
            if workouts > 0 || duplicates > 0 {
                lines.append("Imported \(workouts) workouts, \(sets) sets.")
            }
            if duplicates > 0 { lines.append("Skipped \(duplicates) workouts already in the app.") }
            if let w = bodyWeight { lines.append("Body weight set to \(w.formatted(.number.precision(.fractionLength(0...1)))) lbs.") }
            if !unmatched.isEmpty {
                lines.append("Not found, skipped: " + unmatched.sorted().joined(separator: ", ") + ".")
            }
            if unknownFile { lines.append("A file was not a Hevy export and was skipped.") }
            return lines.isEmpty ? "Nothing to import." : lines.joined(separator: "\n")
        }
    }

    static func importFiles(_ urls: [URL], into context: ModelContext) -> Result {
        var result = Result()
        for url in urls {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                result.unknownFile = true
                continue
            }
            let rows = CSV.parse(text)
            guard let header = rows.first else { continue }
            if header.contains("exercise_title") {
                importWorkouts(rows, into: context, result: &result)
            } else if header.contains("weight_lbs") && header.contains("date") {
                importWeight(rows, into: context, result: &result)
            } else {
                result.unknownFile = true
            }
        }
        try? context.save()
        return result
    }

    // MARK: Workouts

    private static func importWorkouts(_ rows: [[String]], into context: ModelContext, result: inout Result) {
        let header = rows[0]
        func col(_ name: String) -> Int? { header.firstIndex(of: name) }
        guard let cTitle = col("title"), let cStart = col("start_time"), let cEnd = col("end_time"),
              let cExercise = col("exercise_title"), let cReps = col("reps") else { return }
        let cWeightLbs = col("weight_lbs"), cWeightKg = col("weight_kg")
        let cSeconds = col("duration_seconds"), cMiles = col("distance_miles"), cKm = col("distance_km")
        func number(_ row: [String], _ c: Int?) -> Double? {
            guard let c, c < row.count, let v = Double(row[c]), v > 0 else { return nil }
            return v
        }

        // Weights are stored in the unit chosen in Profile.
        let profileKg = ((try? context.fetch(FetchDescriptor<UserProfile>()))?.first?.weightUnit == .kg)

        // Existing workouts, to skip ones already imported.
        let existing = Set(((try? context.fetch(FetchDescriptor<Workout>())) ?? [])
            .map { Int($0.startedAt.timeIntervalSince1970 / 60) })

        // Group rows by workout (title + start time), keeping file order.
        var order: [String] = []
        var groups: [String: [[String]]] = [:]
        for row in rows.dropFirst() where row.count > max(cTitle, cStart, cExercise, cReps) {
            let key = row[cStart] + "|" + row[cTitle]
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(row)
        }

        for key in order {
            guard let rows = groups[key], let first = rows.first,
                  let start = parseDate(first[cStart]) else { continue }
            if existing.contains(Int(start.timeIntervalSince1970 / 60)) {
                result.duplicates += 1
                continue
            }
            let workout = Workout(routineName: first[cTitle], routineCreatedAt: nil)
            workout.startedAt = start
            workout.endedAt = parseDate(first[cEnd]) ?? start
            var exerciseOrder: [String] = []
            var setsByExercise: [String: [(weight: Double, reps: Int, seconds: Int?, miles: Double?)]] = [:]
            for row in rows {
                let reps = Int(row[cReps]) ?? 0
                let seconds = number(row, cSeconds).map { Int($0) }
                let miles = number(row, cMiles) ?? number(row, cKm).map { $0 / 1.60934 }
                guard reps > 0 || seconds != nil || miles != nil else { continue } // empty row
                let name = row[cExercise]
                guard let id = exerciseID(for: name) else {
                    result.unmatched.insert(name)
                    continue
                }
                var weight: Double = 0
                if let c = cWeightLbs, c < row.count, let lbs = Double(row[c]) {
                    weight = profileKg ? lbs / 2.20462 : lbs
                } else if let c = cWeightKg, c < row.count, let kg = Double(row[c]) {
                    weight = profileKg ? kg : kg * 2.20462
                }
                weight = (weight * 10).rounded() / 10
                if setsByExercise[id] == nil { exerciseOrder.append(id) }
                setsByExercise[id, default: []].append((weight, reps, seconds, miles))
            }
            guard !exerciseOrder.isEmpty else { continue }
            context.insert(workout)
            for (i, id) in exerciseOrder.enumerated() {
                let we = WorkoutExercise(exerciseID: id, order: i, restSeconds: 90)
                we.workout = workout
                context.insert(we)
                for (j, s) in (setsByExercise[id] ?? []).enumerated() {
                    let ws = WorkoutSet(order: j, weight: s.weight, reps: s.reps)
                    ws.durationSeconds = s.seconds
                    ws.distanceMiles = s.miles
                    ws.done = true
                    ws.workoutExercise = we
                    context.insert(ws)
                    result.sets += 1
                }
            }
            result.workouts += 1
        }
    }

    // MARK: Body weight

    private static func importWeight(_ rows: [[String]], into context: ModelContext, result: inout Result) {
        let header = rows[0]
        guard let cDate = header.firstIndex(of: "date"), let cWeight = header.firstIndex(of: "weight_lbs") else { return }
        var latest: (Date, Double)?
        for row in rows.dropFirst() where row.count > max(cDate, cWeight) {
            guard let d = parseDate(row[cDate]), let w = Double(row[cWeight]), w > 0 else { continue }
            if latest == nil || d > latest!.0 { latest = (d, w) }
        }
        guard let (_, lbs) = latest else { return }
        let profile: UserProfile
        if let p = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first {
            profile = p
        } else {
            profile = UserProfile()
            context.insert(profile)
        }
        profile.weightKg = lbs / 2.20462
        result.bodyWeight = lbs
    }

    // MARK: Helpers

    /// "17 Nov 2026, 16:18" in the phone's time zone.
    static func parseDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        for format in ["d MMM yyyy, HH:mm", "d MMM yyyy, H:mm", "yyyy-MM-dd HH:mm:ss"] {
            f.dateFormat = format
            if let d = f.date(from: s) { return d }
        }
        return nil
    }

    private static let aliases: [String: String] = {
        guard let url = Bundle.main.url(forResource: "hevy_names", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return map
    }()

    private static func normalized(_ s: String) -> String {
        s.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static let byNormalizedName: [String: String] = {
        var map: [String: String] = [:]
        for ex in ExerciseLibrary.shared.exercises {
            map[normalized(ex.name)] = map[normalized(ex.name)] ?? ex.id
            if let o = ex.originalName { map[normalized(o)] = map[normalized(o)] ?? ex.id }
        }
        return map
    }()

    static func exerciseID(for hevyName: String) -> String? {
        if let id = aliases[hevyName.lowercased()] { return id }
        return byNormalizedName[normalized(hevyName)]
    }
}

/// Minimal CSV reader: commas, quoted fields, "" inside quotes, CRLF or LF.
enum CSV {
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var chars = text.makeIterator()
        var pending: Character? = nil
        func next() -> Character? {
            if let p = pending { pending = nil; return p }
            return chars.next()
        }
        while let c = next() {
            if inQuotes {
                if c == "\"" {
                    if let n = next() {
                        if n == "\"" { field.append("\"") } else { inQuotes = false; pending = n }
                    } else { inQuotes = false }
                } else {
                    field.append(c)
                }
            } else if c == "\"" {
                inQuotes = true
            } else if c == "," {
                row.append(field); field = ""
            } else if c == "\n" || c == "\r\n" || c == "\r" {
                row.append(field); field = ""
                if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
                row = []
            } else {
                field.append(c)
            }
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}
