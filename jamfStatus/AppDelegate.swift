import SwiftUI

@main
struct JamfStatusApp: App {
    @StateObject private var monitor = MonitorViewModel()
    @AppStorage("hideMenubarIcon") private var hideMenubarIcon: Bool = false

    init() {
        initializeTelemetryDeck()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(monitor)
        } label: {
            if hideMenubarIcon {
                Image("minimizedIcon").renderingMode(.original)
            } else {
                Image(monitor.menuBarIconName).renderingMode(.original)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(monitor)
        }

        Window("Health Status", id: "health-status") {
            HealthStatusView()
        }
        .defaultSize(width: 560, height: 220)
        .windowResizability(.contentSize)

        Window("jamfStatus", id: "cloud-status") {
            CloudStatusWebView(url: URL(string: "https://status.jamf.com")!)
        }
        .defaultSize(width: 900, height: 600)

        Window("About jamfStatus", id: "about") {
            AboutView()
                .environmentObject(monitor)
        }
        .defaultSize(width: 460, height: 360)
        .windowResizability(.contentSize)
    }
}
