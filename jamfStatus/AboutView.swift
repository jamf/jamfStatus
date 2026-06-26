import SwiftUI

struct AboutView: View {
    @EnvironmentObject var monitor: MonitorViewModel
    @AppStorage("optOut") private var optOut: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)

            Text(AppInfo.name)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(AppInfo.version) (\(AppInfo.build))")
                .foregroundStyle(.secondary)

            ScrollView {
                Text(attributedBody())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .frame(height: 180)

            Toggle("Opt out of analytics", isOn: $optOut)
                .onChange(of: optOut) { newValue in
                    TelemetryDeckConfig.OptOut = newValue
                }

            HStack {
                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/jamf/jamfStatus") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("File an Issue") {
                    if let url = URL(string: "https://github.com/jamf/jamfStatus/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .padding(24)
        .onAppear { NSApp.activate(ignoringOtherApps: true) }
    }

    private func attributedBody() -> AttributedString {
        let year = Calendar.current.component(.year, from: Date())
        var result = AttributedString("""
        This application monitors Jamf Cloud status and Jamf Pro server health.

        By default, jamfStatus sends anonymous usage data to TelemetryDeck to aid development.

        Copyright \(year), Jamf Software, LLC. Licensed under the Jamf Concepts Use Agreement.
        """)

        if let range = result.range(of: "Jamf Concepts Use Agreement") {
            result[range].link = URL(string: "https://resources.jamf.com/documents/jamf-concept-projects-use-agreement.pdf")
        }
        return result
    }
}
