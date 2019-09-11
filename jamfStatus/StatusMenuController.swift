//StatusMenuController.swift
//Author: Leslie Helou
//Copyright 2017 Jamf Professional Services
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import AppKit
import Cocoa
//import WebKit

class StatusMenuController: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        
    let defaults = UserDefaults.standard
    let prefs = Preferences()
    
    @IBOutlet weak var alert_window: NSPanel!
    @IBOutlet weak var cloudStatusMenu: NSMenu!
    @IBOutlet weak var notifications_MenuItem: NSMenuItem!
    @IBOutlet weak var status_Toolbar: NSToolbar!
    
    @IBOutlet weak var alert_TextView: NSTextField!
    @IBOutlet weak var alert_TextFieldCell: NSTextFieldCell!
    
    @IBOutlet weak var alert_ImageCell: NSImageCell!
    
    let fileManager = FileManager.default
    let cloudStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let statusURL = "https://status.jamf.com"
    var statusPageString = ""
    var dataString = ""
    var theResult = ""
    var displayedStatus = ""
    var iconName = ""
    var icon = NSImage(named: "cloudStatus-red")
    
    @IBOutlet weak var alertWindowPref_Button: NSButton!
    var alert_header = ""
    var alert_message = ""
    var serviceCount = 0

    var alert_image_green = NSImage(named: "greenCloud")
    var alert_image_yellow = NSImage(named: "yellowCloud")
    var alert_image_red = NSImage(named: "redCloud")
    var current_alert_pref = "green"
    var prevState = "cloudStatus-green"
    
    // Settings vars
    let myBundlePath = Bundle.main.bundlePath
    let SettingsPlistPath = NSHomeDirectory()+"/Library/Preferences/com.jamf.jamfstatus.plist"
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list file
    
    var settingsPlistData:[String:Any] = [:]
    
    var affectedServices = ""
    
    @IBOutlet weak var alert_ImageView: NSImageView!
    
    @IBAction func quitCloudStatus(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    override func awakeFromNib() {
        
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
        
        if (defaults.object(forKey:"jamfServerUrl") as? String == nil) {
            defaults.set("", forKey: "jamfServerUrl")
            prefs.jamfServerUrl = ""
        } else {
            prefs.jamfServerUrl = defaults.string(forKey:"jamfServerUrl")!
            let credentialsArray = Credentials2().retrieve(service: "jamfStatus: \(prefs.jamfServerUrl)")
            if credentialsArray.count == 2 {
                prefs.username = credentialsArray[0]
                prefs.password = credentialsArray[1]
            } else {
                prefs.username = ""
                prefs.password = ""
            }
        }
        
        defaults.synchronize()
        
        icon = NSImage(named: iconName)
//        icon?.isTemplate = true // best for dark mode?
        cloudStatusItem.image = icon
        cloudStatusItem.menu = cloudStatusMenu
        DispatchQueue.global(qos: .background).async {
            while true {
                
                // check site server - start
                UapiCall().get(endpoint: "notifications/alerts") {
                    (notificationAlerts: [Dictionary<String, Any>]) in
                    
                    print("returned from checking site server")
                    if notificationAlerts.count == 0 {
                        self.notifications_MenuItem.isHidden = true
                    } else {
                        self.notifications_MenuItem.isHidden = false
                        let subMenu      = NSMenu()
                        var displayTitle = ""
                        var subTitle     = ""
                        // alert types found here:
                        // .../tomcat/webapps/ROOT/ui/notifications/notification-alert.model.js
                        // to-do: add preferences to allow selection of alerts to show
                        self.cloudStatusMenu.setSubmenu(subMenu, for: self.notifications_MenuItem)
                        for alert in notificationAlerts {
                            let alertTitle = alert["type"]! as! String
                            switch alertTitle {
                            case "EXCEEDED_LICENSE_COUNT":
                                displayTitle = "Exceeded License Count"
                            case "VPP_ACCOUNT_EXPIRED":
                                displayTitle = "VPP Account Has Expired"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tname: \(String(describing: paramDict["name"]!))"
                            case "VPP_ACCOUNT_WILL_EXPIRE":
                                displayTitle = "VPP Account Will Expire"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tname: \(String(describing: paramDict["name"]!)) - days to expire: \(String(describing: paramDict["days"]!))"
                            case "VPP_ACCOUNT_REVOKED":
                                displayTitle = "VPP Token Has Been Revoked"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tname: \(String(describing: paramDict["name"]!))"
                            case "DEP_INSTANCE_EXPIRED":
                                displayTitle = "DEP Instance Has Expired"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tname: \(String(describing: paramDict["name"]!))"
                            case "DEP_INSTANCE_WILL_EXPIRE":
                                displayTitle = "DEP Instance Will Expire"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tname: \(String(describing: paramDict["name"]!)) - days to expire: \(String(describing: paramDict["days"]!))"
                            case "DEVICE_ENROLLMENT_PROGRAM_T_C_NOT_SIGNED":
                                displayTitle = "DEP Terms And Conditions Are Not Signed"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tinstanceName: \(String(describing: paramDict["name"]!))"
                            case "TOMCAT_SSL_CERT_EXPIRED":
                                displayTitle = "Tomcat SSL Certificate Has Expired"
                            case "TOMCAT_SSL_CERT_WILL_EXPIRE":
                                displayTitle = "Tomcat SSL Certificate Will Expire"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tdays to expire: \(String(describing: paramDict["days"]!))"
                            case "SSO_CERT_EXPIRED":
                                displayTitle = "SSO Certificate Has Expired"
                            case "SSO_CERT_WILL_EXPIRE":
                                displayTitle = "SSO Certificate Will Expire"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tdays to expire: \(String(describing: paramDict["days"]!))"
                            case "GSX_CERT_EXPIRED":
                                displayTitle = "GSX Certificate Has Expired"
                            case "GSX_CERT_WILL_EXPIRE":
                                displayTitle = "GSX Certificate Will Expire"
                                let paramDict = alert["params"] as! Dictionary<String, Any>
                                subTitle = "\tdays to expire: \(String(describing: paramDict["days"]!))"
                            default:
                                displayTitle = ""
                                subTitle     = ""
                            }
                            print("alert: \(alert)")
                            print("alertTitle: \(alertTitle)")
                            subMenu.addItem(NSMenuItem(title: "\(displayTitle)", action: nil, keyEquivalent: ""))
                            if subTitle != "" {
                                subMenu.addItem(NSMenuItem(title: "\(subTitle)", action: nil, keyEquivalent: ""))
                                subTitle = ""
                            }
                        }
//                            NSApplication.shared.mainMenu = self.cloudStatusMenu
                    }
                    
                }
                // check site server - end

                //                print("checking status")
                self.prefs.pollingInterval = self.defaults.integer(forKey: "pollingInterval")
                self.prefs.hideMenubarIcon = self.defaults.bool(forKey: "hideMenubarIcon")
                self.getStatus2() {
                    (result: String) in
                    
                    DispatchQueue.main.async {
                        self.iconName = result
                        //                        AppDlg.hideIcon ? (self.icon = NSImage.init(named: NSImage.Name(rawValue: "minimizedIcon"))):(self.icon = NSImage.init(named: NSImage.Name(rawValue: self.iconName)))
                        //                        print("iconName: \(result)")
                        //                        print("hidemenubar is \(self.prefs.hideMenubarIcon!)")
                        self.prefs.hideMenubarIcon! ? (self.icon = NSImage.init(named: "minimizedIcon")):(self.icon = NSImage.init(named: self.iconName))
                        
                        self.cloudStatusItem.image = self.icon
                    }
                }
                sleep(UInt32(Int(self.prefs.pollingInterval!)))
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
            // adjust font size so that alert message fits in text box.
            alertHeight = 99
            //            print("count: \(self.alert_message.count)")
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
            //            self.serviceCount > 2 ? (alertHeight = 99 + 18*(self.serviceCount-2)):(alertHeight = 99)
            self.alert_window.setContentSize(NSSize(width: 398, height:alertHeight))
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
    
    func refreshAlert() {
        self.alert_window.title = "\(alert_header)"
        self.alert_TextFieldCell.stringValue = self.alert_message
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
        
        //        JSON parsing - start
        let apiStatusUrl = "\(String(describing: prefs.baseUrl!))/api/v2/components.json"
//        print("apiStatusUrl: \(apiStatusUrl)")
        //        let apiStatusUrl = "https://test.server/cloudstatus/components.json"
        
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
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
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
                self.iconName =  localResult
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
    
}
