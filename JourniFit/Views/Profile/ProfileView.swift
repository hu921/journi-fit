import SwiftUI
import SwiftData
import PhotosUI

/// Round profile icon: photo, initials, or a person symbol.
struct ProfileAvatar: View {
    let profile: UserProfile?
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            if let data = profile?.photo, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let initials = profile?.initials, !initials.isEmpty {
                Theme.primary
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Theme.primary.opacity(0.15)
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Theme.primary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// Opens the profile. Creates it on first open.
struct ProfileButton: View {
    @Query private var profiles: [UserProfile]
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            ProfileAvatar(profile: profiles.first, size: 40)
        }
        .accessibilityLabel("Profile")
        .sheet(isPresented: $show) { ProfileSheet() }
    }
}

/// Profile as a tab. Creates the profile on first open.
struct ProfileTab: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileForm(profile: profile)
                } else {
                    ProgressView().onAppear { context.insert(UserProfile()) }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

private struct ProfileSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileForm(profile: profile)
                } else {
                    ProgressView().onAppear { context.insert(UserProfile()) }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct ProfileForm: View {
    @Bindable var profile: UserProfile
    @State private var photoItem: PhotosPickerItem?
    /// Which wheel is open. Only one at a time; closed by default.
    @State private var openWheel: Wheel?
    @FocusState private var typing: Bool

    enum Wheel { case birthday, height }

    private func toggle(_ wheel: Wheel) {
        typing = false
        withAnimation { openWheel = openWheel == wheel ? nil : wheel }
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        ProfileAvatar(profile: profile, size: 96)
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, Theme.primary)
                            }
                    }
                    Text(profile.fullName.isEmpty ? "Your name" : profile.fullName)
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section("Name") {
                TextField("First name", text: $profile.firstName)
                    .focused($typing)
                    .textContentType(.givenName)
                TextField("Last name", text: $profile.lastName)
                    .focused($typing)
                    .textContentType(.familyName)
            }

            Section("Birthday") {
                Button {
                    if profile.birthday == nil {
                        profile.birthday = Calendar.current.date(byAdding: .year, value: -30, to: .now)
                    }
                    toggle(.birthday)
                } label: {
                    HStack {
                        Text(profile.birthday?.formatted(date: .long, time: .omitted) ?? "Add birthday")
                            .foregroundStyle(Theme.text)
                        Spacer()
                        if let age = profile.age {
                            Text("Age \(age)").foregroundStyle(Theme.primary).bold()
                        }
                    }
                }
                if openWheel == .birthday {
                    DatePicker("Birthday",
                               selection: Binding(get: { profile.birthday ?? .now },
                                                  set: { profile.birthday = $0 }),
                               in: ...Date.now,
                               displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            }

            Section("Weight") {
                Picker("Unit", selection: $profile.weightUnit) {
                    Text("lbs").tag(WeightUnit.lb)
                    Text("kg").tag(WeightUnit.kg)
                }
                .pickerStyle(.segmented)
                HStack {
                    TextField("0", value: $profile.displayWeight,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .focused($typing)
                    Text(profile.weightUnit == .lb ? "lbs" : "kg").foregroundStyle(Theme.muted)
                }
            }

            Section("Height") {
                Picker("Unit", selection: $profile.heightUnit) {
                    Text("ft in").tag(HeightUnit.ftIn)
                    Text("cm").tag(HeightUnit.cm)
                }
                .pickerStyle(.segmented)
                if profile.heightUnit == .cm {
                    HStack {
                        TextField("0", value: $profile.heightCm, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .focused($typing)
                        Text("cm").foregroundStyle(Theme.muted)
                    }
                } else {
                    Button { toggle(.height) } label: {
                        HStack {
                            Text(profile.heightCm > 0 ? profile.heightText : "Add height")
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Image(systemName: openWheel == .height ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                    if openWheel == .height {
                    HStack(spacing: 0) {
                        Picker("Feet", selection: $profile.feet) {
                            ForEach(3...8, id: \.self) { Text("\($0) ft").tag($0) }
                        }
                        Picker("Inches", selection: $profile.inches) {
                            ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .onAppear { if profile.heightCm == 0 { profile.feet = 5; profile.inches = 6 } }
                    }
                }
            }
        }
        // Typing in any field closes an open wheel.
        .onChange(of: typing) { _, isTyping in
            if isTyping { withAnimation { openWheel = nil } }
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .onChange(of: photoItem) { _, item in
            Task { profile.photo = try? await item?.loadTransferable(type: Data.self) }
        }
    }
}
