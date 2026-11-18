import SwiftUI
import SwiftData

/// Home screen: routines as cards, each with a Start Routine button.
struct RoutineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var finished: [Workout]
    @State private var showNew = false
    @State private var path: [Routine] = []
    @State private var toDelete: Routine?

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 0) {
                // App title and profile icon on one line.
                HStack(alignment: .center) {
                    Text(AppInfo.name)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.text)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Text("Routines")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal)
                    .padding(.top, 4)

                Group {
                if routines.isEmpty {
                    ContentUnavailableView("No routines yet",
                                           systemImage: "list.bullet.clipboard",
                                           description: Text("Tap New Routine to build your first one."))
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
                        .padding(.bottom, 72) // room for the New Routine button
                    }
                }
                }
                .frame(maxHeight: .infinity)
            }
            .background(Theme.background)
            .navigationTitle("Routines")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Routine.self) { RoutineEditorView(routine: $0) }
            // Easy-to-reach add button, bottom right above the tab bar.
            .overlay(alignment: .bottomTrailing) {
                Button { showNew = true } label: {
                    Label("New Routine", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Theme.primary, in: Capsule())
                        .shadow(color: Theme.primary.opacity(0.35), radius: 8, y: 4)
                }
                .padding()
            }
            .sheet(isPresented: $showNew) {
                NewRoutineSheet { name in
                    let routine = Routine(name: name)
                    context.insert(routine)
                    path.append(routine) // open it so exercises can be added right away
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
        }
    }
}

/// Name a new routine. One tap on Create saves, even with the keyboard open.
/// (A system alert needed two taps: the first only closed the keyboard.)
private struct NewRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool
    let onCreate: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("New routine")
                .font(.headline)
                .foregroundStyle(Theme.text)

            TextField("Routine name, e.g. Push Day", text: $name)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(create)
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.muted.opacity(0.3)))

            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(Theme.text)
                        .background(Theme.muted.opacity(0.15), in: Capsule())
                }
                Button(action: create) {
                    Text("Create")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Theme.primary, in: Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.background)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        onCreate(trimmed.isEmpty ? "New routine" : trimmed)
        dismiss()
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
