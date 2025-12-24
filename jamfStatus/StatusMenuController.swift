//StatusMenuController.swift
//Author: Leslie Helou
//Copyright 2017 Jamf Professional Services


import AppKit
import Cocoa
import Foundation
import OSLog

class StatusMenuController: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        
    let prefs = Preferences.self
    let myObserverClass = MyObserverClass()
    
    @IBOutlet weak var alert_window: NSPanel!
    @IBOutlet weak var cloudStatusMenu: NSMenu!
    @IBOutlet weak var notifications_MenuItem: NSMenuItem!
    @IBOutlet weak var status_Toolbar: NSToolbar!
    
    @IBOutlet weak var alert_TextView: NSTextField!
    @IBOutlet weak var alert_TextFieldCell: NSTextFieldCell!
    
    @IBOutlet weak var alert_ImageCell: NSImageCell!
    
    let fileManager      = FileManager.default
    let cloudStatusItem  = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//    let statusURL        = "https://status.jamf.com"
    var statusPageString = ""
    var dataString       = ""
    var theResult        = ""
    var displayedStatus  = ""
    var iconName         = ""
    var icon             = NSImage(named: "cloudStatus-red")
    
    @IBOutlet weak var alertWindowPref_Button: NSButton!
    var alert_header  = ""
    var alert_message = ""
    var serviceCount  = 0

    var alert_image_green  = NSImage(named: "greenCloud")
    var alert_image_yellow = NSImage(named: "yellowCloud")
    var alert_image_red    = NSImage(named: "redCloud")
    var current_alert_pref = "green"
    var prevState          = "cloudStatus-green"
    
    // Settings vars
    let myBundlePath      = Bundle.main.bundlePath
    let SettingsPlistPath = NSHomeDirectory()+"/Library/Preferences/com.jamf.jamfstatus.plist"
    var format            = PropertyListSerialization.PropertyListFormat.xml //format of the property list file
    
    var settingsPlistData:[String:Any] = [:]
    
    var affectedServices = ""
    
    @IBOutlet weak var alert_ImageView: NSImageView!
    
    @IBAction func quitCloudStatus(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    override func awakeFromNib() {
        
        myObserverClass.setupObserver()
        
        // OS version info
        let os = ProcessInfo().operatingSystemVersion
        
        writeToLog.message(stringOfText: [""])
        writeToLog.message(stringOfText: ["================================================================"])
        writeToLog.message(stringOfText: ["    \(AppInfo.displayname) Version: \(AppInfo.version) build: \(AppInfo.build)"])
        writeToLog.message(stringOfText: ["         macOS Version: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"])
        writeToLog.message(stringOfText: ["================================================================"])
        writeToLog.message(stringOfText: ["additionsl logging available from Terminal using:"])
        writeToLog.message(stringOfText: ["log stream --debug --predicate 'subsystem == \"\(Bundle.main.bundleIdentifier!)\"'"])
        Task {@MainActor in
            configureTelemetryDeck()
            writeToLog.message(stringOfText: ["analytics enabled: \(!TelemetryDeckConfig.OptOut)"])
        }
        
        useApiClient = defaults.integer(forKey: "useApiClient")
       
        if (defaults.object(forKey:"pollingInterval") as? Int == nil) {
            prefs.pollingInterval = 300
        } else {
            prefs.pollingInterval = defaults.object(forKey:"pollingInterval") as? Int ?? 300
        }
        
        if prefs.pollingInterval ?? 0 < 60 {
            prefs.pollingInterval = 300
            defaults.set(prefs.pollingInterval, forKey: "pollingInterval")
        }
        
        if (defaults.object(forKey:"hideUntilStatusChange") as? Bool == nil){
            defaults.set(true, forKey: "hideUntilStatusChange")
            prefs.hideUntilStatusChange = true
        } else {
            prefs.hideUntilStatusChange = defaults.bool(forKey:"hideUntilStatusChange")
        }
        
        if (defaults.object(forKey:"hideMenubarIcon") as? Bool == nil) {
            defaults.set(false, forKey: "hideMenubarIcon")
            prefs.hideMenubarIcon = false
        } else {
            prefs.hideMenubarIcon = defaults.bool(forKey: "hideMenubarIcon")
        }
        
        if (defaults.object(forKey:"launchAgent") as? Bool == nil){
            defaults.set(false, forKey: "launchAgent")
            prefs.launchAgent = false
        } else {
            prefs.launchAgent = defaults.bool(forKey:"launchAgent")
        }
        
        if (defaults.object(forKey:"baseUrl") as? String == nil) {
            defaults.set("https://status.jamf.com", forKey: "baseUrl")
            prefs.baseUrl = "https://status.jamf.com"
        } else {
            prefs.baseUrl = defaults.string(forKey:"baseUrl") ?? "https://status.jamf.com"
        }
        
        // set menu icon style
        prefs.menuIconStyle = defaults.string(forKey: "menuIconStyle") ?? prefs.menuIconStyle
        
        if (defaults.object(forKey:"jamfServerUrl") as? String == nil) {
            defaults.set("", forKey: "jamfServerUrl")
            JamfProServer.url = ""
        } else {
            JamfProServer.url = defaults.string(forKey:"jamfServerUrl")!
            let credentialsArray = Credentials().itemLookup(service: JamfProServer.url.fqdnFromUrl)
            if credentialsArray.count == 2 {
                JamfProServer.username = credentialsArray[0]
                JamfProServer.password = credentialsArray[1]
            } else {
                JamfProServer.password = ""
            }
        }
        
        
        icon = NSImage(named: iconName)
//        icon?.isTemplate = true // best for dark mode?
//        cloudStatusItem.image = icon
        cloudStatusItem.button?.image = icon
        cloudStatusItem.menu = cloudStatusMenu
        
        JamfProServer.base64Creds = ("\(JamfProServer.username):\(JamfProServer.password)".data(using: .utf8)?.base64EncodedString())!
        Task {
            await monitor()
        }
        
    }
    
    func monitor() async {
//        DispatchQueue.global(qos: .background).async { [self] in
            while true {
                
                // check site server - start
                Logger.check.info("checking server: \(JamfProServer.url, privacy: .public)")
                UapiCall().get(endpoint: "v1/notifications") { [self]
                    (notificationAlerts: [[String: Any]]) in
                    
                    if notificationAlerts.count == 0 {
                        notifications_MenuItem.isHidden = true
                    } else {
                        notifications_MenuItem.title = "Notifications (\(notificationAlerts.count))"
                        notifications_MenuItem.isHidden = false
                        let subMenu      = NSMenu()
                        var displayTitleKey = ""
                        var displayTitle = ""
                        cloudStatusMenu.setSubmenu(subMenu, for: notifications_MenuItem)
                        for alert in notificationAlerts {
//                            print("notification alert: \(alert)")
                            let alertTitle = alert["type"] as? String ?? "Unknown"
                            displayTitleKey = JamfNotification.key[alertTitle] ?? "Unknown"
                            displayTitle = JamfNotification.displayTitle[displayTitleKey] ?? "Unknown"
                            if displayTitle == "Unknown" {
                                writeToLog.message(stringOfText: ["unknown alert: \(alert.description.replacingOccurrences(of: "\n", with: ""))"])
                                displayTitle = alertTitle
                            }
                            switch displayTitleKey {
                            case "CERT_WILL_EXPIRE", "CERT_EXPIRED":
                                displayTitle = displayTitle.replacingOccurrences(of: "{{certType}}", with: "\(String(describing: JamfNotification.humanReadable[alertTitle]!))")
                            default:
                                break
                            }
                            let paramDict = alert["params"] as! [String: Any]
                            for (key,value) in paramDict {
//                                print("key: \(key)     value: \(value)")
                                displayTitle = displayTitle.replacingOccurrences(of: "{{\(key)}}", with: "\(value)")
                            }
                            subMenu.addItem(NSMenuItem(title: "\(displayTitle)", action: #selector(AppDelegate.notificationsAction(_:)), keyEquivalent: ""))
                            subMenu.item(withTitle: "\(displayTitle)")?.identifier = NSUserInterfaceItemIdentifier.init(rawValue: displayTitleKey)
                        }
                    }
                    
                }
                // check site server - end

                //                print("checking status")
                prefs.pollingInterval = (defaults.integer(forKey: "pollingInterval") < 60 ? 300 : defaults.integer(forKey: "pollingInterval"))
                prefs.hideMenubarIcon = false // defaults.bool(forKey: "hideMenubarIcon")
                
                let result = (try? await getStatus2()) ?? "cloudStatus-green"
                try? await healthStatus()
                
                DispatchQueue.main.async { [self] in
                    iconName = result
                    //                        AppDlg.hideIcon ? (icon = NSImage.init(named: NSImage.Name(rawValue: "minimizedIcon"))):(icon = NSImage.init(named: NSImage.Name(rawValue: iconName)))
                    //                        print("iconName: \(result)")
                    //                        print("hidemenubar is \(prefs.hideMenubarIcon!)")
                    prefs.hideMenubarIcon! ? (icon = NSImage.init(named: "minimizedIcon")):(icon = NSImage.init(named: iconName))
                    
                    //                        cloudStatusItem.image = icon
                    cloudStatusItem.button?.image = icon
                }
                sleep(UInt32(Int(prefs.pollingInterval!)))
            }
    }
    
    @IBAction func alertWindowPref_Action(_ sender: NSButton) {
        
        if alertWindowPref_Button.state.rawValue == 0 {
            defaults.set(false, forKey: "hideUntilStatusChange")
        } else {
            defaults.set(false, forKey: "hideUntilStatusChange")
        }
    }
    
    func displayAlert(currentState: String) {
//        var alertHeight = 0
        
        DispatchQueue.main.async {
            /*
            // adjust font size so that alert message fits in text box.
            alertHeight = 99
            //            print("count: \(alert_message.count)")
            let alertLines = self.alert_message.split(separator: "\n")
            //            print("alerts: \(alertLines)")
            for i in 1..<alertLines.count {
                //                print("line count: \(alertLines[i].count)")
                let lineLength = alertLines[i].count/55 as Int
                //                print("lineLength: \(lineLength)")
                if ( i < 3 ) {
                    alertHeight += 18*(lineLength)
                } else {
                    alertHeight += 18*(lineLength+1)
                }
            }
            */
            //            self.serviceCount > 2 ? (alertHeight = 99 + 18*(self.serviceCount-2)):(alertHeight = 99)
           
//            self.alert_window.setContentSize(NSSize(width: 398, height:alertHeight))
            
            if self.alert_message.count > 55 {
                self.alert_TextView.font = NSFont(name: "Arial", size: 12.0)
            } else {
                self.alert_TextView.font = NSFont(name: "Arial", size: 18.0)
            }
            if (defaults.bool(forKey:"hideUntilStatusChange")) {
                self.alertWindowPref_Button.state = NSControl.StateValue.on
            } else {
                self.alertWindowPref_Button.state = NSControl.StateValue.off
            }
            if self.prevState != currentState {
                DispatchQueue.main.async {
                    self.refreshAlert()
                }
            } else {
                if !(defaults.bool(forKey:"hideUntilStatusChange")) && self.prevState != "cloudStatus-green" {
                    DispatchQueue.main.async {
                        self.refreshAlert()
                    }
                }
            }
            self.prevState = currentState
        }   // DispatchQueue.main.async - end
    }
    
    @IBAction func showLogs_Action(_ sender: Any) {
        if fileManager.fileExists(atPath: Log.path! + Log.file) {
//            NSWorkspace.shared.openFile(Log.path! + Log.file)
            NSWorkspace.shared.open(URL(fileURLWithPath: "\(Log.path!)\(Log.file)"))
        }
    }
    
    
    func refreshAlert() {
        self.alert_window.title = "\(alert_header)"
        self.alert_TextFieldCell.stringValue = self.alert_message
        WriteToLog().message(stringOfText: [alert_header, self.alert_message])
        if self.alert_window.isVisible {
            self.alert_window.setIsVisible(false)
            sleep(1)
        }
        self.alert_window.setIsVisible(true)
    }
    
//    func getStatus2(completion: @escaping (_ result: String) -> Void) {
//        Task {
    @MainActor
    func getStatus2() async throws -> String {
        
        if TokenManager.shared.tokenInfo?.authMessage ?? "" == "success" {
            var localResult = ""
            
            var operationalArray = [String]()
            var warningArray     = [String]()
            var criticalArray    = [String]()
            
            // clear current arrays
            operationalArray.removeAll()
            warningArray.removeAll()
            criticalArray.removeAll()
            affectedServices = ""
            URLCache.shared.removeAllCachedResponses()
            
            Logger.check.info("checking Jamf Cloud")
            //        JSON parsing - start
            let apiStatusUrl = "\(prefs.baseUrl)/api/v2/components.json"
    //        url to test app - need to set up your own
    //        need to create the folder /jamfStatus and populate the page: components.json
    //        let apiStatusUrl = "http://your.jamfpro.server/jamfStatus/components.json"
            
            URLCache.shared.removeAllCachedResponses()
            let encodedURL = URL(string: apiStatusUrl)!
            var request = URLRequest(url: encodedURL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            
            configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken)", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw HealthStatusError.invalidResponse
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                    let cloudServices = json["components"] as? [[String: Any]] {
//                        print("cloudServices: \(cloudServices)")
                    for cloudService in cloudServices {
                        if let name = cloudService["name"] as? String,
                            let status = cloudService["status"] as? String {
                            switch status {
                            case "degraded_performance", "partial_outage":
                                if status == "partial_outage" {
                                    self.displayedStatus = "Partial Outage"
                                } else {
                                    self.displayedStatus = "Degraded Performance"
                                }
                                warningArray.append(name + ": " + self.displayedStatus)
                            case "major_outage":
                                self.displayedStatus = "Major Outage"
                                criticalArray.append(name + ": " + self.displayedStatus)
                            default:
                                self.displayedStatus = "Operational"
                                operationalArray.append(name + ": " + self.displayedStatus)
                            }
                        }
                    }
                }
            } catch {
                print("Error deserializing JSON: \(error)")
            }   // do - end

            if criticalArray.count > 0 {
                self.alert_header = "Jamf Cloud Critical Issue Alert"
                localResult = "cloudStatus-red"
                for service in criticalArray {
                    self.affectedServices.append("    \(service)\n")
                }
                self.alert_ImageView.image = self.alert_image_red
                self.alert_message = "Please be aware there is a major issue that may affect your Jamf Cloud instance.\n\(self.affectedServices)"
                self.serviceCount = criticalArray.count
                self.displayAlert(currentState: localResult)
            } else if warningArray.count > 0 {
                self.alert_header = "Jamf Cloud Minor Issue Alert"
                localResult = "cloudStatus-yellow"
                for service in warningArray {
                    self.affectedServices.append("    \(service)\n")
                }
                self.alert_ImageView.image = self.alert_image_yellow
                self.alert_message = "Please be aware there is a minor issue that may affect your Jamf Cloud instance.\n\(self.affectedServices)"
                self.serviceCount = warningArray.count
                self.displayAlert(currentState: localResult)
            } else if operationalArray.count > 0 {
                self.alert_header = "Notice"
                localResult = "cloudStatus-green"
//                localResult = "cloudMajor-18"
                self.affectedServices = ""
                self.alert_ImageView.image = self.alert_image_green
                self.alert_message = "\nJamf Cloud: All systems go."
                self.serviceCount = 0
                self.displayAlert(currentState: localResult)
            }
            
            //            print("operationalArray: \(operationalArray)\n")
            //            print("warningArray: \(warningArray)\n")
            //            print("criticalArray: \(criticalArray)\n")
            
            if (localResult != "cloudStatus-green") && (localResult != "cloudStatus-yellow") && (localResult != "cloudStatus-red") {
                self.iconName = "minimizedIcon"
            } else {
                if (self.prefs.menuIconStyle == "color") || (localResult == "cloudStatus-green") {
                    // display icon with color
                    self.iconName = localResult
                } else {
                    // display icon with slash
                    self.iconName = (localResult == "cloudStatus-yellow") ? "cloudStatus-yellow1":"cloudStatus-red1"
                    localResult = self.iconName
                }
            }
            return(localResult)
        }
        return("cloudStatus-green")
    }
    
    @MainActor
    private func healthStatus() async throws {

        guard TokenManager.shared.tokenInfo?.authMessage == "success" else {
            Logger.check.info("health status was not updated")
            throw HealthStatusError.authenticationFailed
        }

        Logger.check.info("checking server health status")

        let apiStatusURL = URL(string: "\(JamfProServer.url)/api/v1/health-status")!

        var request = URLRequest(url: apiStatusURL)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(JamfProServer.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppInfo.userAgentHeader, forHTTPHeaderField: "User-Agent")

        URLCache.shared.removeAllCachedResponses()

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw HealthStatusError.invalidResponse
        }

        let decodedHealthStatus = try JSONDecoder().decode(HealthStatus.self, from: data)

        HealthStatusStore.shared.update(from: decodedHealthStatus)

        Logger.check.info("health status updated")
        
        // log rates below 1.0
        if let _ = HealthStatusStore.shared.healthStatus {
            await logHealthStatus(HealthStatusStore.shared.healthStatus!.api, area: "API")
            await logHealthStatus(HealthStatusStore.shared.healthStatus!.ui, area: "UI")
            await logHealthStatus(HealthStatusStore.shared.healthStatus!.enrollment, area: "Enrollment")
            await logHealthStatus(HealthStatusStore.shared.healthStatus!.device, area: "Device")
            await logHealthStatus(HealthStatusStore.shared.healthStatus!.healthStatusDefault, area: "Default")
        }
    }
    
    private func logHealthStatus(_ values: API, area: String) async {
        let apiMirror = Mirror(reflecting: values as API)
        var percents: [String] = []
        for timeInterval in apiMirror.children {
            if let label = timeInterval.label {
                if let theRate = timeInterval.value as? Double, theRate < 1.0  {
                    percents.append("    \(label): \(timeInterval.value)")
                }
            }
        }
        if !percents.isEmpty {
            writeToLog.message(stringOfText: ["\(area) rate warning:"])
            writeToLog.message(stringOfText: percents)
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

