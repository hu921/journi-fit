import Foundation
import SwiftData

enum WeightUnit: String, CaseIterable, Identifiable {
    case lb, kg
    var id: String { rawValue }
}

enum HeightUnit: String, CaseIterable, Identifiable {
    case cm, ftIn
    var id: String { rawValue }
    var label: String { self == .cm ? "cm" : "ft in" }
}

/// The user's own profile. One per user. Stored in metric; shown in the chosen unit.
@Model
final class UserProfile {
    var firstName: String = ""
    var lastName: String = ""
    var birthday: Date?
    var weightKg: Double = 0
    var weightUnitRaw: String = WeightUnit.lb.rawValue
    var heightCm: Double = 0
    var heightUnitRaw: String = HeightUnit.ftIn.rawValue
    @Attribute(.externalStorage) var photo: Data?

    init() {}

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .lb }
        set { weightUnitRaw = newValue.rawValue }
    }

    var heightUnit: HeightUnit {
        get { HeightUnit(rawValue: heightUnitRaw) ?? .ftIn }
        set { heightUnitRaw = newValue.rawValue }
    }

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let letters = [firstName.first, lastName.first].compactMap { $0 }
        return letters.isEmpty ? "" : String(letters).uppercased()
    }

    var age: Int? {
        guard let birthday else { return nil }
        return Calendar.current.dateComponents([.year], from: birthday, to: .now).year
    }

    /// Weight in the chosen unit.
    var displayWeight: Double {
        get { weightUnit == .kg ? weightKg : weightKg * 2.20462 }
        set { weightKg = weightUnit == .kg ? newValue : newValue / 2.20462 }
    }

    var feet: Int {
        get { Int(heightCm / 2.54) / 12 }
        set { heightCm = Double(newValue * 12 + inches) * 2.54 }
    }

    var inches: Int {
        get { Int((heightCm / 2.54).rounded()) % 12 }
        set { heightCm = Double(feet * 12 + newValue) * 2.54 }
    }

    var heightText: String {
        guard heightCm > 0 else { return "Not set" }
        return heightUnit == .cm ? "\(Int(heightCm.rounded())) cm" : "\(feet) ft \(inches) in"
    }

    var weightText: String {
        guard weightKg > 0 else { return "Not set" }
        return "\(displayWeight.formatted(.number.precision(.fractionLength(0...1)))) \(weightUnit.rawValue)"
    }
}
