import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @State private var showNew = false
    @State private var showFileImport = false
    @State private var newName = ""
    @Environment(RoutineImporter.self) private var importer

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    ContentUnavailableView("No routines yet",
                                           systemImage: "list.bullet.clipboard",
                                           description: Text("Tap + to build your first routine."))
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink(value: routine) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(routine.name).font(.headline)
                                    Text("\(routine.items?.count ?? 0) exercises")
                                        .font(.caption).foregroundStyle(Theme.muted)
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { routines[$0] }.forEach(context.delete)
                        }
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Routines")
            .navigationDestination(for: Routine.self) { RoutineEditorView(routine: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFileImport = true } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Label("New routine", systemImage: "plus") }
                }
            }
            .alert("New routine", isPresented: $showNew) {
                TextField("Name", text: $newName)
                Button("Cancel", role: .cancel) { newName = "" }
                Button("Create") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    context.insert(Routine(name: trimmed.isEmpty ? "New routine" : trimmed))
                    newName = ""
                }
            }
            .fileImporter(isPresented: $showFileImport, allowedContentTypes: [.journiFitRoutine]) { result in
                if case .success(let url) = result { importer.handle(url: url) }
            }
        }
    }
}
