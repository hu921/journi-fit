import SwiftUI

/// About: app info, privacy, support, more from journipod, credits.
/// Links still missing in AppInfo show the name only, as a placeholder.
struct AboutView: View {
    var body: some View {
        List {
            // 1. App name, version and build, plus tagline
            Section {
                VStack(spacing: 8) {
                    Image("AboutIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    Text(AppInfo.name).font(.title.bold()).foregroundStyle(Theme.text)
                    Text(AppInfo.tagline).font(.subheadline).foregroundStyle(Theme.muted)
                    Text("Version \(AppInfo.version)").font(.caption).foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // 3. Privacy
            Section {
                LinkRow(title: "Privacy Policy", systemImage: "hand.raised.fill", url: AppInfo.privacyPolicyURL)
            } header: {
                Text("Privacy")
            } footer: {
                Text("Your workouts stay on your iPhone and in your own iCloud. journipod does not collect them.")
            }

            // 4 and 5. Support and rating
            Section("Support") {
                LinkRow(title: "Contact us", systemImage: "envelope.fill",
                        url: AppInfo.supportEmail.flatMap { URL(string: "mailto:\($0)?subject=journi%20Fit%20\(AppInfo.version)") })
                LinkRow(title: "Rate on the App Store", systemImage: "star.fill", url: AppInfo.reviewURL)
            }

            // 8. More from journipod
            Section("More from journipod") {
                LinkRow(title: "journi Diary", systemImage: "book.closed.fill", url: AppInfo.journiDiaryURL)
            }

            // 6 and 2. Credits and copyright
            Section {
                LinkRow(title: "Exercise data: Free Exercise DB", systemImage: "dumbbell.fill", url: AppInfo.exerciseDataURL)
            } header: {
                Text("Credits")
            } footer: {
                Text(AppInfo.copyright)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A row that opens a link, or shows just the name while the link is not set.
private struct LinkRow: View {
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        if let url {
            Link(destination: url) {
                HStack {
                    Label(title, systemImage: systemImage).foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Theme.muted)
                }
            }
        } else {
            Label(title, systemImage: systemImage).foregroundStyle(Theme.text)
        }
    }
}
