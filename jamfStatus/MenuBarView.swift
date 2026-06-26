import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var monitor: MonitorViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // Notifications submenu
        if !monitor.notifications.isEmpty {
            Menu("Notifications (\(monitor.notifications.count))") {
                ForEach(monitor.notifications) { note in
                    Text(note.displayTitle)
                }
            }
        }

        Divider()

        if #available(macOS 14.0, *) {
            SettingsLink { Text("Settings…") }
        } else {
            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
        }

        Button("Jamf Cloud Status") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "cloud-status")
        }

        Button("Health Status") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "health-status")
        }

        Divider()

        Button("Check for Updates…") {
            checkForUpdates()
        }

        Button("Show Logs") {
            showLogs()
        }

        Button("About jamfStatus") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "about")
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func checkForUpdates() {
        let version = AppInfo.version
        VersionCheck().versionCheck { updateAvailable in
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText     = "Running jamfStatus: \(version)"
                alert.informativeText = updateAvailable
                    ? "A new version is available."
                    : "No updates are currently available."
                alert.alertStyle = .informational
                if updateAvailable {
                    alert.addButton(withTitle: "View")
                    alert.addButton(withTitle: "Ignore")
                } else {
                    alert.addButton(withTitle: "OK")
                }
                let response = alert.runModal()
                if response == .alertFirstButtonReturn && updateAvailable {
                    if let url = URL(string: "https://github.com/jamf/jamfStatus/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    private func showLogs() {
        let path = (Log.path ?? "") + Log.file
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}
