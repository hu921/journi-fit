import Foundation
import SwiftData

/// Optional, free-form diet notes. No calorie database in version 1.
@Model
final class DietNote {
    var date: Date = Date.now
    var text: String = ""

    init(date: Date = .now, text: String) {
        self.date = date
        self.text = text
    }
}
