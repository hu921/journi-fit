import SwiftUI

/// Rest time between sets for one exercise: Off, 15s ... 5min.
struct RestPicker: View {
    @Binding var seconds: Int

    var body: some View {
        Picker(selection: $seconds) {
            ForEach(Array(stride(from: 0, through: 300, by: 15)), id: \.self) { s in
                Text(s == 0 ? "Off" : Self.format(s)).tag(s)
            }
        } label: {
            Label("Rest between sets", systemImage: "timer").foregroundStyle(Theme.primary)
        }
    }

    static func format(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m)min" : "\(m)min \(s)s"
    }
}
