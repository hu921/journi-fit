import SwiftUI

/// All app colors live here.
/// PLACEHOLDER: replace these hex values with the journi Diary palette.
enum Theme {
    static let primary    = Color(hex: 0x6C8EBF) // main brand color
    static let secondary  = Color(hex: 0xF2B880) // accents, highlights
    static let background = Color(hex: 0xFAF7F2) // screen background
    static let surface    = Color(hex: 0xFFFFFF) // cards
    static let text       = Color(hex: 0x2E2E2E) // body text
    static let muted      = Color(hex: 0x8A8A8A) // secondary text
    static let success    = Color(hex: 0x7BB98F) // goal reached
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
