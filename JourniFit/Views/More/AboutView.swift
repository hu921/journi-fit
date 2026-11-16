import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(Theme.primary)
            Text(AppInfo.name).font(.largeTitle.bold())
            Text("Version \(AppInfo.version)").foregroundStyle(Theme.muted)
            Spacer()
            Text("Exercise data from the open-source Free Exercise DB.")
                .font(.footnote).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Text(AppInfo.copyright).font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
