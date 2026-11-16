import SwiftUI
import SwiftData
import PhotosUI

/// The user's gym: its machines, with personal settings.
/// Members can share a gym's machine list by file or link.
struct MyGymView: View {
    @Environment(\.modelContext) private var context
    @Environment(RoutineImporter.self) private var importer
    @Query(sort: \GymProfile.createdAt) private var profiles: [GymProfile]
    @Query(sort: \GymMachine.addedAt) private var machines: [GymMachine]
    @State private var showCustom = false
    @State private var showImport = false
    @State private var showEditGym = false

    private var profile: GymProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showEditGym = true } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile?.name.isEmpty == false ? profile!.name : "Name your gym")
                                .font(.title3.bold())
                                .foregroundStyle(Theme.text)
                            Label(profile?.location.isEmpty == false ? profile!.location : "Add location",
                                  systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }

                if machines.isEmpty {
                    Section {
                        Text("Add machines from Finder, add a custom machine, or import a list from a gym member.")
                            .foregroundStyle(Theme.muted)
                    }
                } else {
                    Section("\(machines.count) machines") {
                        ForEach(machines) { machine in
                            NavigationLink { GymMachineEditor(machine: machine) } label: {
                                GymMachineRow(machine: machine)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { machines[$0] }.forEach(context.delete)
                        }
                    }
                }

                Section {
                    Button { showCustom = true } label: {
                        Label("Add custom machine", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("My Gym")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showImport = true } label: {
                        Label("Import gym", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    let shared = SharedGym(profile: profile, machines: machines)
                    Menu {
                        if let link = shared.link { ShareLink("Share as link", item: link) }
                        ShareLink("Share as file", item: shared, preview: SharePreview(shared.title))
                    } label: {
                        Label("Share gym", systemImage: "square.and.arrow.up")
                    }
                    .disabled(machines.isEmpty)
                }
            }
            .sheet(isPresented: $showCustom) { CustomMachineView() }
            .sheet(isPresented: $showEditGym) { EditGymView(profile: profile) }
            .fileImporter(isPresented: $showImport, allowedContentTypes: [.journiFitGym]) { result in
                if case .success(let url) = result { importer.handle(url: url) }
            }
        }
    }
}

private struct GymMachineRow: View {
    let machine: GymMachine

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = machine.photo, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else if let exercise = machine.exercise {
                    ExerciseImage(exercise: exercise)
                } else {
                    ZStack {
                        Theme.primary.opacity(0.15)
                        Image(systemName: "wrench.and.screwdriver").foregroundStyle(Theme.primary)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(machine.displayName).font(.headline)
                if machine.isCustom {
                    Text("Custom").font(.caption2.bold()).foregroundStyle(Theme.primary)
                }
                if !machine.settings.isEmpty {
                    Text(machine.settings).font(.caption).foregroundStyle(Theme.muted)
                }
            }
        }
    }
}

private struct EditGymView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let profile: GymProfile?
    @State private var name = ""
    @State private var location = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Gym name (e.g. UFC Gym)", text: $name)
                TextField("Location (e.g. Torrance, CA)", text: $location)
            }
            .navigationTitle("My gym")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                name = profile?.name ?? ""
                location = profile?.location ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let p = profile ?? {
                            let new = GymProfile()
                            context.insert(new)
                            return new
                        }()
                        p.name = name.trimmingCharacters(in: .whitespaces)
                        p.location = location.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                }
            }
        }
    }
}

/// A machine the exercise database does not have.
private struct CustomMachineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscle: String = ""
    @State private var settings = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Machine name", text: $name)
                    Picker("Main muscle", selection: $muscle) {
                        Text("Not set").tag("")
                        ForEach(ExerciseLibrary.shared.muscles, id: \.self) {
                            Text($0.capitalized).tag($0)
                        }
                    }
                    TextField("Settings or notes", text: $settings, axis: .vertical)
                }
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photo == nil ? "Add photo" : "Change photo", systemImage: "camera")
                    }
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle("Custom machine")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: photoItem) { _, item in
                Task { photo = try? await item?.loadTransferable(type: Data.self) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let m = GymMachine(customName: name.trimmingCharacters(in: .whitespaces),
                                           customMuscle: muscle, settings: settings)
                        m.photo = photo
                        context.insert(m)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

private struct GymMachineEditor: View {
    @Bindable var machine: GymMachine
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Form {
            if let exercise = machine.exercise {
                Section {
                    NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                        ExerciseRow(exercise: exercise)
                    }
                }
            } else {
                Section("Custom machine") {
                    TextField("Machine name", text: $machine.customName)
                    Picker("Main muscle", selection: $machine.customMuscle) {
                        Text("Not set").tag("")
                        ForEach(ExerciseLibrary.shared.muscles, id: \.self) {
                            Text($0.capitalized).tag($0)
                        }
                    }
                }
            }

            Section("My notes") {
                TextField("Name or spot (e.g. near the window)", text: $machine.nickname)
                TextField("Settings (seat height, pin…)", text: $machine.settings, axis: .vertical)
                HStack {
                    Text("Last weight")
                    Spacer()
                    TextField("0", value: $machine.lastWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section("Photo") {
                if let data = machine.photo, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(machine.photo == nil ? "Add photo of this machine" : "Change photo",
                          systemImage: "camera")
                }
            }

            if !machine.muscles.isEmpty {
                Section("Similar exercises") {
                    ForEach(similar) { ex in
                        NavigationLink { ExerciseDetailView(exercise: ex) } label: {
                            ExerciseRow(exercise: ex)
                        }
                    }
                }
            }
        }
        .navigationTitle(machine.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { _, item in
            Task { machine.photo = try? await item?.loadTransferable(type: Data.self) }
        }
    }

    private var similar: [Exercise] {
        let lib = ExerciseLibrary.shared
        if let exercise = machine.exercise { return lib.similar(to: exercise) }
        return Array(lib.exercises.filter { !$0.primaryMuscles.filter(machine.muscles.contains).isEmpty }
            .sorted { ($0.machine != nil ? 1 : 0) > ($1.machine != nil ? 1 : 0) }
            .prefix(8))
    }
}
