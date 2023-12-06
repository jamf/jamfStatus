//StatusMenuController.swift
//Author: Leslie Helou
//Copyright 2017 Jamf Professional Services


import AppKit
import Cocoa
import Foundation

class StatusMenuController: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        
    let defaults = UserDefaults.standard
    let prefs = Preferences.self
    
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
        
        useApiClient = defaults.integer(forKey: "useApiClient")
       
        if (defaults.object(forKey:"pollingInterval") as? Int == nil) {
            defaults.set(300, forKey: "pollingInterval")
            prefs.pollingInterval = 300
        } else {
            prefs.pollingInterval = defaults.object(forKey:"pollingInterval") as? Int
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
            prefs.baseUrl = defaults.string(forKey:"baseUrl")
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
//
//        defaults.synchronize()
//        
//        defaults.synchronize()
        
        icon = NSImage(named: iconName)
//        icon?.isTemplate = true // best for dark mode?
//        cloudStatusItem.image = icon
        cloudStatusItem.button?.image = icon
        cloudStatusItem.menu = cloudStatusMenu
        
        JamfProServer.base64Creds = ("\(JamfProServer.username):\(JamfProServer.password)".data(using: .utf8)?.base64EncodedString())!
            monitor()
        
    }
    
    func monitor() {
        DispatchQueue.global(qos: .background).async { [self] in
            while true {
                
                // check site server - start
                WriteToLog().message(stringOfText: ["checking server: \(Preferences.jamfServerUrl)"])
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
                            let alertTitle = alert["type"]! as! String
                            displayTitleKey = JamfNotification.key[alertTitle] ?? "Unknown"
                            displayTitle = JamfNotification.displayTitle[displayTitleKey] ?? "Unknown"
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
                prefs.pollingInterval = defaults.integer(forKey: "pollingInterval")
                prefs.hideMenubarIcon = defaults.bool(forKey: "hideMenubarIcon")
                getStatus2() {
                    (result: String) in
                    
                    DispatchQueue.main.async { [self] in
                        iconName = result
                        //                        AppDlg.hideIcon ? (icon = NSImage.init(named: NSImage.Name(rawValue: "minimizedIcon"))):(icon = NSImage.init(named: NSImage.Name(rawValue: iconName)))
                        //                        print("iconName: \(result)")
                        //                        print("hidemenubar is \(prefs.hideMenubarIcon!)")
                        prefs.hideMenubarIcon! ? (icon = NSImage.init(named: "minimizedIcon")):(icon = NSImage.init(named: iconName))
                        
//                        cloudStatusItem.image = icon
                        cloudStatusItem.button?.image = icon
                    }
                }
                sleep(UInt32(Int(prefs.pollingInterval!)))
            }
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
        var alertHeight = 0
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
            if (self.defaults.bool(forKey:"hideUntilStatusChange")) {
                self.alertWindowPref_Button.state = NSControl.StateValue.on
            } else {
                self.alertWindowPref_Button.state = NSControl.StateValue.off
            }
            if self.prevState != currentState {
                DispatchQueue.main.async {
                    self.refreshAlert()
                }
            } else {
                if !(self.defaults.bool(forKey:"hideUntilStatusChange")) && self.prevState != "cloudStatus-green" {
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
    
    func getStatus2(completion: @escaping (_ result: String) -> Void) {
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
        
        WriteToLog().message(stringOfText: ["checking Jamf Cloud"])
        //        JSON parsing - start
        let apiStatusUrl = "\(String(describing: prefs.baseUrl!))/api/v2/components.json"
//        url to test app - need to set up your own
//        need to create the folder /jamfStatus and populate the page: components.json
//        let apiStatusUrl = "http://your.jamfpro.server/jamfStatus/components.json"
        
        URLCache.shared.removeAllCachedResponses()
        let encodedURL = NSURL(string: apiStatusUrl)
        let request = NSMutableURLRequest(url: encodedURL! as URL)
        request.httpMethod = "GET"
        let configuration = URLSessionConfiguration.default
        
        configuration.httpAdditionalHeaders = ["Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if (response as? HTTPURLResponse) != nil {
                do {
                    if let data = data,
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
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
            }   // if let httpResponse - end
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
            
            completion(localResult)
        })   // let task - end
        task.resume()
//        print("")
        //        JSON parsing - end
    }
    
    func readSettings() -> NSMutableDictionary? {
        if fileManager.fileExists(atPath: SettingsPlistPath) {
            guard let dict = NSMutableDictionary(contentsOfFile: SettingsPlistPath) else { return .none }
            return dict
        } else {
            return .none
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}
