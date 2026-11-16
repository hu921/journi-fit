import SwiftUI

/// Settings. Version 1 holds import only; more options come later.
struct SettingsView: View {
    @Environment(RoutineImporter.self) private var importer
    @State private var showRoutineImport = false
    @State private var showGymImport = false

    var body: some View {
        List {
            Section {
                Button { showRoutineImport = true } label: {
                    Label("Import routine file", systemImage: "square.and.arrow.down")
                }
                Button { showGymImport = true } label: {
                    Label("Import gym file", systemImage: "dumbbell")
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Open a .journifit routine or .journigym gym file someone shared with you.")
            }
        }
        .navigationTitle("Settings")
        .fileImporter(isPresented: $showRoutineImport, allowedContentTypes: [.journiFitRoutine]) { result in
            if case .success(let url) = result { importer.handle(url: url) }
        }
        .fileImporter(isPresented: $showGymImport, allowedContentTypes: [.journiFitGym]) { result in
            if case .success(let url) = result { importer.handle(url: url) }
        }
    }
}
