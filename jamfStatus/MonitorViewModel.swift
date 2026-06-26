import SwiftUI
import OSLog

// MARK: - ParsedNotification

struct ParsedNotification: Identifiable {
    let id = UUID()
    let displayTitle: String
    let key: String

    init?(raw: [String: Any]) {
        guard let alertTitle = raw["type"] as? String else { return nil }
        let titleKey = JamfNotification.key[alertTitle] ?? "Unknown"
        var title = JamfNotification.displayTitle[titleKey] ?? alertTitle

        switch titleKey {
        case "CERT_WILL_EXPIRE", "CERT_EXPIRED":
            let certType = JamfNotification.humanReadable[alertTitle] ?? alertTitle
            title = title.replacingOccurrences(of: "{{certType}}", with: certType)
        default: break
        }

        let params = raw["params"] as? [String: Any] ?? [:]
        for (k, v) in params {
            title = title.replacingOccurrences(of: "{{\(k)}}", with: "\(v)")
        }

        self.displayTitle = title
        self.key          = titleKey
    }
}

// MARK: - MonitorViewModel

@MainActor
final class MonitorViewModel: ObservableObject {

    @Published var menuBarIconName: String = "cloudStatus-green"
    @Published var notifications: [ParsedNotification] = []
    @Published var connectionStatus: ConnectionStatus = .unknown

    enum ConnectionStatus { case unknown, connected, failed }

    private var prevState: String = "cloudStatus-green"
    private var monitorTask: Task<Void, Never>?

    private let fm = FileManager.default
    private let launchAgentPath = NSHomeDirectory() + "/Library/LaunchAgents/com.jamf.cloudmonitor.plist"

    init() {
        if UserDefaults.standard.object(forKey: "pollingInterval") == nil {
            UserDefaults.standard.set(300, forKey: "pollingInterval")
        }
        if UserDefaults.standard.object(forKey: "hideUntilStatusChange") == nil {
            UserDefaults.standard.set(true, forKey: "hideUntilStatusChange")
        }
        if UserDefaults.standard.object(forKey: "hideMenubarIcon") == nil {
            UserDefaults.standard.set(false, forKey: "hideMenubarIcon")
        }
        if UserDefaults.standard.object(forKey: "launchAgent") == nil {
            UserDefaults.standard.set(false, forKey: "launchAgent")
        }

        let serverUrl = (UserDefaults.standard.string(forKey: "jamfServerUrl") ?? "").baseUrl
        if !serverUrl.isEmpty {
            JamfProServer.url = serverUrl
            let creds = Credentials().itemLookup(service: serverUrl.fqdn)
            if creds.count == 2 {
                JamfProServer.username = creds[0]
                JamfProServer.password = creds[1]
            }
        }

        let os = ProcessInfo().operatingSystemVersion
        writeToLog.message(stringOfText: [""])
        writeToLog.message(stringOfText: ["================================================================"])
        writeToLog.message(stringOfText: ["    \(AppInfo.displayname) Version: \(AppInfo.version) build: \(AppInfo.build)"])
        writeToLog.message(stringOfText: ["         macOS Version: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"])
        writeToLog.message(stringOfText: ["================================================================"])

        startMonitoring()
    }

    // MARK: - Monitor loop

    func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                let interval = max(
                    UserDefaults.standard.integer(forKey: "pollingInterval"), 60
                )
                try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
            }
        }
    }

    private func tick() async {
        Logger.check.info("checking server: \(JamfProServer.url, privacy: .public)")
        await refreshNotifications()
        let iconResult = (try? await getCloudStatus()) ?? "cloudStatus-green"
        try? await refreshHealthStatus()
        updateMenuBarIcon(for: iconResult)
    }

    // MARK: - Notifications

    private func refreshNotifications() async {
        await withCheckedContinuation { continuation in
            UapiCall().get(endpoint: "v1/notifications") { [weak self] alerts in
                guard let self else { continuation.resume(); return }
                self.notifications = alerts.compactMap { ParsedNotification(raw: $0) }
                continuation.resume()
            }
        }
    }

    // MARK: - Cloud status

    private func getCloudStatus() async throws -> String {
        guard await TokenManager.shared.tokenInfo?.authMessage == "success" else {
            return "cloudStatus-green"
        }

        let apiUrl = "\(Preferences.baseUrl)/api/v2/components.json"
        guard let url = URL(string: apiUrl) else { return "cloudStatus-green" }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Authorization": "Bearer \(JamfProServer.accessToken)",
            "Accept": "application/json",
            "User-Agent": AppInfo.userAgentHeader
        ]
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw HealthStatusError.invalidResponse
        }

        var operational = [String](), warning = [String](), critical = [String]()
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let components = json["components"] as? [[String: Any]] {
            for c in components {
                guard let name   = c["name"]   as? String,
                      let status = c["status"] as? String else { continue }
                switch status {
                case "major_outage":          critical.append("\(name): Major Outage")
                case "partial_outage":        warning.append("\(name): Partial Outage")
                case "degraded_performance":  warning.append("\(name): Degraded Performance")
                default:                      operational.append("\(name): Operational")
                }
            }
        }

        let hideUntilChange = UserDefaults.standard.bool(forKey: "hideUntilStatusChange")

        if !critical.isEmpty {
            let body = critical.map { "    \($0)" }.joined(separator: "\n")
            maybeShowAlert(
                header: "Jamf Cloud Critical Issue Alert",
                message: "Please be aware there is a major issue that may affect your Jamf Cloud instance.\n\(body)",
                state: "cloudStatus-red",
                hideUntilChange: hideUntilChange
            )
            return "cloudStatus-red"
        } else if !warning.isEmpty {
            let body = warning.map { "    \($0)" }.joined(separator: "\n")
            maybeShowAlert(
                header: "Jamf Cloud Minor Issue Alert",
                message: "Please be aware there is a minor issue that may affect your Jamf Cloud instance.\n\(body)",
                state: "cloudStatus-yellow",
                hideUntilChange: hideUntilChange
            )
            return "cloudStatus-yellow"
        } else {
            maybeShowAlert(
                header: "Notice",
                message: "\nJamf Cloud: All systems go.",
                state: "cloudStatus-green",
                hideUntilChange: hideUntilChange
            )
            return "cloudStatus-green"
        }
    }

    private func maybeShowAlert(header: String, message: String, state: String, hideUntilChange: Bool) {
        let stateChanged = prevState != state
        let shouldShow   = stateChanged || (!hideUntilChange && prevState != "cloudStatus-green")
        if shouldShow {
            let alert = NSAlert()
            alert.messageText     = header
            alert.informativeText = message
            alert.alertStyle      = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        prevState = state
    }

    private func updateMenuBarIcon(for result: String) {
        let style = UserDefaults.standard.string(forKey: "menuIconStyle") ?? "color"
        if style == "color" || result == "cloudStatus-green" {
            menuBarIconName = result
        } else {
            menuBarIconName = result == "cloudStatus-yellow" ? "cloudStatus-yellow1" : "cloudStatus-red1"
        }
    }

    // MARK: - Health status

    private func refreshHealthStatus() async throws {
        guard await TokenManager.shared.tokenInfo?.authMessage == "success",
              !JamfProServer.url.isEmpty,
              let url = URL(string: "\(JamfProServer.url)/api/v1/health-status") else { return }

        var request = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(JamfProServer.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppInfo.userAgentHeader, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw HealthStatusError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(HealthStatus.self, from: data)
        HealthStatusStore.shared.update(from: decoded)
        NotificationCenter.default.post(name: .updateHealthStatusView, object: nil)
        Logger.check.info("health status updated")
        logHealthRateWarnings(decoded)
    }

    private func logHealthRateWarnings(_ hs: HealthStatus) {
        for (label, api) in [("API", hs.api), ("UI", hs.ui), ("Enrollment", hs.enrollment),
                              ("Device", hs.device), ("Default", hs.healthStatusDefault)] {
            let mirror = Mirror(reflecting: api)
            let low = mirror.children.compactMap { child -> String? in
                guard let name = child.label, let rate = child.value as? Double, rate < 1.0 else { return nil }
                return "    \(name): \(rate)"
            }
            if !low.isEmpty {
                writeToLog.message(stringOfText: ["\(label) rate warning:"] + low)
            }
        }
    }

    // MARK: - Credential management

    func loadCredentials() {
        let serverUrl = (UserDefaults.standard.string(forKey: "jamfServerUrl") ?? "").baseUrl
        guard !serverUrl.isEmpty else { return }
        JamfProServer.url = serverUrl
        let creds = Credentials().itemLookup(service: serverUrl.fqdn)
        if creds.count == 2 {
            JamfProServer.username = creds[0]
            JamfProServer.password = creds[1]
        } else {
            JamfProServer.username = ""
            JamfProServer.password = ""
        }
    }

    func saveCredentials(server: String, username: String, password: String) {
        guard !server.isEmpty, !username.isEmpty, !password.isEmpty else { return }
        JamfProServer.url      = server
        JamfProServer.username = username
        JamfProServer.password = password
        JamfProServer.base64Creds = (
            "\(username):\(password)".data(using: .utf8)?.base64EncodedString()
        ) ?? ""
        JamfProServer.validToken = false
        connectionStatus = .unknown

        Task {
            await TokenManager.shared.setToken(
                serverUrl: server,
                username: username.lowercased(),
                password: password
            )
            let authMessage = await TokenManager.shared.tokenInfo?.authMessage ?? ""
            if authMessage == "success" {
                UserDefaults.standard.set(server, forKey: "jamfServerUrl")
                Credentials().save(service: server.fqdn, account: username, data: password)
                connectionStatus = .connected
            } else {
                connectionStatus = .failed
            }
        }
    }

    // MARK: - LaunchAgent

    func applyLaunchAgent(_ enable: Bool) {
        if enable {
            guard !fm.fileExists(atPath: launchAgentPath) else { return }
            let dir = NSHomeDirectory() + "/Library/LaunchAgents"
            if !fm.fileExists(atPath: dir) {
                try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
            }
            let src = Bundle.main.bundlePath + "/Contents/Resources/com.jamf.cloudmonitor.plist"
            try? fm.copyItem(atPath: src, toPath: launchAgentPath)
        } else {
            if fm.fileExists(atPath: launchAgentPath) {
                try? fm.removeItem(atPath: launchAgentPath)
            }
        }
    }
}
