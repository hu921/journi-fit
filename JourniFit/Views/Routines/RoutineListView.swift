import SwiftUI
import SwiftData

/// Home screen: routines as cards, each with a Start Routine button.
struct RoutineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var finished: [Workout]
    @State private var showNew = false
    @State private var showFileImport = false
    @State private var newName = ""
    @State private var toDelete: Routine?
    @Environment(RoutineImporter.self) private var importer

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    ContentUnavailableView("No routines yet",
                                           systemImage: "list.bullet.clipboard",
                                           description: Text("Tap + to build your first routine."))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(routines) { routine in
                                RoutineCard(routine: routine,
                                            last: finished.first { $0.routineCreatedAt == routine.createdAt })
                                    .contextMenu {
                                        Button("Delete routine", systemImage: "trash", role: .destructive) {
                                            toDelete = routine
                                        }
                                    }
                            }
                        }
                        .padding()
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
            .confirmationDialog("Delete \(toDelete?.name ?? "routine")?",
                                isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let toDelete { context.delete(toDelete) }
                    toDelete = nil
                }
            }
            .fileImporter(isPresented: $showFileImport, allowedContentTypes: [.journiFitRoutine]) { result in
                if case .success(let url) = result { importer.handle(url: url) }
            }
        }
    }
}

private struct RoutineCard: View {
    let routine: Routine
    let last: Workout?

    private var exercises: [Exercise] { routine.sortedItems.compactMap(\.exercise) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: routine) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(routine.name).font(.title3.bold()).foregroundStyle(Theme.text)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                    }

                    Text(exercises.isEmpty
                         ? "No exercises yet"
                         : exercises.prefix(3).map(\.name).joined(separator: ", ")
                            + (exercises.count > 3 ? " +\(exercises.count - 3) more" : ""))
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !exercises.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(exercises.prefix(5)) { ex in
                                ExerciseImage(exercise: ex)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Label(exercises.count == 1 ? "1 exercise" : "\(exercises.count) exercises",
                              systemImage: "dumbbell")
                        if let last, let ended = last.endedAt {
                            Label("\(ended.formatted(.dateTime.month(.abbreviated).day())) · \(last.duration.shortString)",
                                  systemImage: "clock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                }
            }
            .buttonStyle(.plain)

            StartRoutineButton(routine: routine)
        }
        .padding()
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
