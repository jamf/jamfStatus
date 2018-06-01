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
import WebKit

class StatusMenuController: NSObject, URLSessionDelegate {

    @IBOutlet weak var alert_window: NSPanel!
    @IBOutlet weak var cloudStatusMenu: NSMenu!
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
    var icon = NSImage(named: NSImage.Name(rawValue: "cloudStatus-red"))
    
    @IBOutlet weak var alertWindowPref_Button: NSButton!
    var alert_header = ""
    var alert_message = ""
    var serviceCount = 0
    var alert_image_green = NSImage(named: NSImage.Name(rawValue: "caution-green"))
    var alert_image_yellow = NSImage(named: NSImage.Name(rawValue: "caution-yellow"))
    var alert_image_red = NSImage(named: NSImage.Name(rawValue: "caution-red"))
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
  
        let AppDlg = AppDelegate()

        icon = NSImage(named: NSImage.Name(rawValue: iconName))
        //icon?.isTemplate = true // best for dark mode
        cloudStatusItem.image = icon
        cloudStatusItem.menu = cloudStatusMenu
        DispatchQueue.global(qos: .background).async {
            while true {
                AppDlg.setDefaultPrefs()
                AppDlg.pollingInterval = UInt32(self.readSettings()?["pollingInterval"]  as! Int32)
                if AppDlg.pollingInterval < 60 {
                    AppDlg.pollingInterval = 300
                    self.settingsPlistData["hideUntilStatusChange"] = self.readSettings()?["hideUntilStatusChange"]  as! Bool
                    self.settingsPlistData["pollingInterval"] = 300     //as Any?
                    // Write info to settings.plist
                    (self.settingsPlistData as NSDictionary).write(toFile: self.SettingsPlistPath, atomically: false)
                }
                print("checking status")
                self.getStatus2() {
                    (result: String) in
                        
                    DispatchQueue.main.async {
                        self.iconName = result
                        AppDlg.hideIcon ? (self.icon = NSImage.init(named: NSImage.Name(rawValue: "minimizedIcon"))):(self.icon = NSImage.init(named: NSImage.Name(rawValue: self.iconName)))

                            self.cloudStatusItem.image = self.icon
                    }
                }
                sleep(UInt32(AppDlg.pollingInterval))
            }
        }
    }
    
    @IBAction func alertWindowPref_Action(_ sender: NSButton) {
        settingsPlistData["pollingInterval"] = readSettings()?["pollingInterval"]  as! Int32
        settingsPlistData["hideMenubarIcon"] = readSettings()?["hideMenubarIcon"]  as! Bool
        if alertWindowPref_Button.state.rawValue == 0 {
            settingsPlistData["hideUntilStatusChange"] = false
        } else {
            settingsPlistData["hideUntilStatusChange"] = true
        }
        // Write info to settings.plist
        (settingsPlistData as NSDictionary).write(toFile: SettingsPlistPath, atomically: true)
    }
    
    func displayAlert(currentState: String) {
        var alertHeight = 0
        DispatchQueue.main.async {
            // adjust font size so that alert message fits in text box.
            print("count: \(self.alert_message.count)")
            self.serviceCount > 2 ? (alertHeight = 99 + 18*(self.serviceCount-2)):(alertHeight = 99)
            self.alert_window.setContentSize(NSSize(width: 398, height:alertHeight))
            if self.alert_message.count > 55 {
                self.alert_TextView.font = NSFont(name: "Arial", size: 12.0)
            } else {
                self.alert_TextView.font = NSFont(name: "Arial", size: 18.0)
            }
            if (self.readSettings()?["hideUntilStatusChange"] as! Bool) {
                self.alertWindowPref_Button.state = NSControl.StateValue.on
            } else {
                self.alertWindowPref_Button.state = NSControl.StateValue.off
            }
            if self.prevState != currentState {
                DispatchQueue.main.async {
                    self.refreshAlert()
                }
            } else {
                if !((self.readSettings()?["hideUntilStatusChange"]) as! Bool) && self.prevState != "cloudStatus-green" {
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
        var warningArray = [String]()
        var criticalArray = [String]()
        
        // clear current arrays
        operationalArray.removeAll()
        warningArray.removeAll()
        criticalArray.removeAll()
        affectedServices = ""
        URLCache.shared.removeAllCachedResponses()
        
        //        JSON parsing - start
        let apiStatusUrl = "https://status.jamf.com/api/v2/components.json"
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
            
            print("operationalArray: \(operationalArray)\n")
            print("warningArray: \(warningArray)\n")
            print("criticalArray: \(criticalArray)\n")
            
            if (localResult != "cloudStatus-green") && (localResult != "cloudStatus-yellow") && (localResult != "cloudStatus-red") {
                self.iconName = "minimizedIcon"
            } else {
                self.iconName =  localResult
            }

          completion(localResult)
        })   // let task - end
        task.resume()
        print("")
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
