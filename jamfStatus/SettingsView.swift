import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: MonitorViewModel

    @AppStorage("pollingInterval")       private var pollingInterval: Int    = 300
    @AppStorage("hideUntilStatusChange") private var hideUntilStatusChange: Bool = true
    @AppStorage("hideMenubarIcon")       private var hideMenubarIcon: Bool   = false
    @AppStorage("menuIconStyle")         private var menuIconStyle: String   = "color"
    @AppStorage("useApiClient")          private var useApiClientRaw: Int    = 0
    @AppStorage("optOut")                private var optOut: Bool            = false

    @State private var serverUrl: String = ""
    @State private var username:  String = ""
    @State private var password:  String = ""

    private var useApiClient: Bool { useApiClientRaw != 0 }

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }

            serverTab
                .tabItem { Label("Server", systemImage: "server.rack") }

            analyticsTab
                .tabItem { Label("Analytics", systemImage: "chart.bar") }
        }
        .padding(20)
        .frame(width: 420, height: 400)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            loadCurrentValues()
        }
    }

    // MARK: - General tab

    private var generalTab: some View {
        Form {
            Section("Polling") {
                Stepper(value: $pollingInterval, in: 60...3600, step: 10) {
                    HStack {
                        Text("Interval (seconds):")
                        TextField("", value: $pollingInterval, format: .number)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .onSubmit { clampPollingInterval() }
                    }
                }
            }

            Section("Menu Bar") {
                Toggle("Hide menubar icon", isOn: $hideMenubarIcon)
                Picker("Icon style:", selection: $menuIconStyle) {
                    Text("Color").tag("color")
                    Text("Slash").tag("slash")
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            Section("Alerts") {
                Toggle("Only alert when status changes", isOn: $hideUntilStatusChange)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Server tab

    private var serverTab: some View {
        Form {
            Section("Authentication") {
                Picker("Type:", selection: $useApiClientRaw) {
                    Text("Username / Password").tag(0)
                    Text("API Client").tag(1)
                }
                .pickerStyle(.segmented)
                .onChange(of: useApiClientRaw) { _ in
                    loadStoredCredentials()
                }
            }

            Section {
                TextField(text: $serverUrl, prompt: Text("https://server.example.com")) {
                    EmptyView()
                }
                .textFieldStyle(.roundedBorder)
                .onSubmit { validateAndSave() }

                TextField(useApiClient ? "Client ID" : "Username", text: $username)
                    .textFieldStyle(.roundedBorder)

                SecureField(useApiClient ? "Secret" : "Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            } header: {
                HStack(spacing: 6) {
                    connectionIndicator
                    Text("Jamf Pro Server")
                }
            }

            HStack {
                Spacer()
                Button("Save") { validateAndSave() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var connectionIndicator: some View {
        let imageName: String = monitor.connectionStatus == .connected ? "green-dot" : "red-dot"
        Image(nsImage: NSImage(named: imageName)!)
            .resizable()
            .frame(width: 10, height: 10)
    }

    // MARK: - Analytics tab

    private var analyticsTab: some View {
        Form {
            Section {
                Toggle("Opt out of analytics", isOn: $optOut)
                    .onChange(of: optOut) { newValue in
                        TelemetryDeckConfig.OptOut = newValue
                    }

                Text("By default, jamfStatus sends anonymous usage data to TelemetryDeck to help improve the app.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Helpers

    private func loadCurrentValues() {
        loadStoredCredentials()
    }

    private func loadStoredCredentials() {
        let stored = (UserDefaults.standard.string(forKey: "jamfServerUrl") ?? "").baseUrl
        serverUrl = stored
        if !stored.isEmpty {
            let creds = Credentials().itemLookup(service: stored.fqdn)
            if creds.count == 2 {
                username = creds[0]
                password = creds[1]
            } else {
                username = JamfProServer.username
                password = ""
            }
        }
    }

    private func clampPollingInterval() {
        if pollingInterval < 60 { pollingInterval = 300 }
    }

    private func validateAndSave() {
        let base = (serverUrl as String).baseUrl
        guard !base.isEmpty else { return }
        serverUrl = base
        monitor.saveCredentials(server: base, username: username, password: password)
    }
}
