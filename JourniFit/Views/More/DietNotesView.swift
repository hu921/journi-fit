import SwiftUI
import SwiftData

/// Optional diet notes. Plain text, one per day or meal.
struct DietNotesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DietNote.date, order: .reverse) private var notes: [DietNote]
    @State private var draft = ""

    var body: some View {
        List {
            Section {
                TextField("What did you eat?", text: $draft, axis: .vertical)
                Button("Add note") {
                    context.insert(DietNote(text: draft))
                    draft = ""
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Section("Notes") {
                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(Theme.muted)
                        Text(note.text)
                    }
                }
                .onDelete { offsets in
                    offsets.map { notes[$0] }.forEach(context.delete)
                }
            }
        }
        .navigationTitle("Diet notes")
    }
}
