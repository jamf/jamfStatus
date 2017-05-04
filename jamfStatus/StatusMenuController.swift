//StatusMenuController.swift
//Copyright 2017 Leslie N. Helou
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
    
    @IBOutlet weak var alert_TextFieldCell: NSTextFieldCell!
    @IBOutlet weak var alert_ImageCell: NSImageCell!
    
    let cloudStatusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let statusURL = "https://status.jamf.com"
    var statusPageString = ""
    var dataString = ""
    var theResult = ""
    var iconName = ""
    var icon = NSImage(named: "cloudStatus-red")
    let services = ["JSS Hosting - US", "JSS Hosting - EU", "Jamf Now", "Jamf Nation", "Jamf Software Website", "Jamf Cloud Push Proxy", "Jamf Cloud Distribution Service", "CDN Services", "DNS", "Compute Services - US", "Database Services - US", "Storage Services - US", "Storage Services - EU", "Jamf Cloud Provisioning Services", "Email Services"]
    
    
    @IBOutlet weak var alertWindowPref_Button: NSButton!
    var alert_image_green = NSImage(named: "caution-green")
    var alert_image_yellow = NSImage(named: "caution-yellow")
    var alert_image_red = NSImage(named: "caution-red")
    var current_alert_pref = "green"
    var prevState = "cloudStatus-green"
    
    // Settings vars
    let myBundlePath = Bundle.main.bundlePath
    let SettingsPlistPath = NSHomeDirectory()+"/Library/Preferences/com.jamf.jamfstatus.plist"
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list file
    
    var settingsPlistData:[String:Any] = [:]
    
    var statusLine = ""
    var statusLine2 = ""

    @IBOutlet weak var alert_ImageView: NSImageView!

    @IBAction func quitCloudStatus(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    override func awakeFromNib() {
        let AppDlg = AppDelegate()

        icon = NSImage(named: iconName)
        //icon?.isTemplate = true // best for dark mode
        cloudStatusItem.image = icon
        cloudStatusItem.menu = cloudStatusMenu
        DispatchQueue.global(qos: .background).async {
            while true {
                AppDlg.setDefaultPrefs()
                AppDlg.pollingInterval = UInt32(self.readSettings()?["pollingInterval"]  as! Int32)
                if AppDlg.pollingInterval < 120 {
                    AppDlg.pollingInterval = 300
                    self.settingsPlistData["hideUntilStatusChange"] = self.readSettings()?["hideUntilStatusChange"]  as! Bool
                    self.settingsPlistData["pollingInterval"] = 300     //as Any?
                    // Write info to settings.plist
                    (self.settingsPlistData as NSDictionary).write(toFile: self.SettingsPlistPath, atomically: false)
                }
                //print("Poll Interval: \(AppDlg.pollingInterval)")
                self.iconName = self.getStatus2()
                self.icon = NSImage.init(named: self.iconName)
                self.cloudStatusItem.image = self.icon
                // added additional sleep and icon mumbo jumbo to get icon to refresh
                sleep(10)
                self.icon = NSImage.init(named: self.iconName)
                self.cloudStatusItem.image = self.icon
                sleep(UInt32(AppDlg.pollingInterval))
            }
        }
    }
    
    @IBAction func alertWindowPref_Action(_ sender: NSButton) {
        settingsPlistData["pollingInterval"] = readSettings()?["pollingInterval"]  as! Int32
        if alertWindowPref_Button.state == 0 {
            settingsPlistData["hideUntilStatusChange"] = false
        } else {
            settingsPlistData["hideUntilStatusChange"] = true
        }
        // Write info to settings.plist
        (settingsPlistData as NSDictionary).write(toFile: SettingsPlistPath, atomically: false)
    }
    
    func displayAlert(currentState: String) {
        if (readSettings()?["hideUntilStatusChange"] as! Bool) {
            alertWindowPref_Button.state = NSOnState
        } else {
            alertWindowPref_Button.state = NSOffState
        }
        if prevState != currentState {
            DispatchQueue.main.async {
                if self.alert_window.isVisible {
                    self.alert_window.setIsVisible(false)
                }
                self.alert_window.setIsVisible(true)
            }
        } else {
            if !((self.readSettings()?["hideUntilStatusChange"]) as! Bool) && prevState != "cloudStatus-green" {
                DispatchQueue.main.async {
                    if self.alert_window.isVisible {
                        self.alert_window.setIsVisible(false)
                    }
                    self.alert_window.setIsVisible(true)
                }
            }
        }
        prevState = currentState
    }
  
    func readSettings() -> NSMutableDictionary? {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: SettingsPlistPath) {
            guard let dict = NSMutableDictionary(contentsOfFile: SettingsPlistPath) else { return .none }
            return dict
        } else {
            return .none
        }
    }

    
    func getStatus2() -> String {
        var localResult = ""
        var indexOfA:Int?
        var statusIndex:Int?
        var counter = 0

        var service:[String] = []
        
        let myURLString = self.statusURL
        guard let myURL = URL(string: myURLString) else {
            print("Error: \(myURLString) doesn't seem to be a valid URL")
            return("Error")
        }
        
        do {
            let statusPageString = try String(contentsOf: myURL, encoding: .ascii)
            //print("\(statusPageString)")
            service = statusPageString.components(separatedBy: "\n")
            // remove leading spaces and tabs
            for theLine in service {
                service[counter] = theLine.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\t", with: "")
                counter += 1
            }
            // try to capture status message from web page - start
            let marker = service.index(of: "<span class=\"status font-large\">")
            let marker2 = service.index(of: "<div class=\"incident-title font-large\">")
            if marker != nil {
                alert_TextFieldCell.stringValue = "Jamf Cloud Status:\n\(service[marker!+1])"
                print("Jamf Cloud: \(service[marker!+1])")
            } else if marker2 != nil {
                statusLine = "\(service[marker2!+1])"
                statusLine2 = ""
                // substring
                if let start = statusLine.range(of: ">"),
                    let end  = statusLine.range(of: "</a>", range: start.upperBound..<statusLine.endIndex) {
                    statusLine2.append(statusLine[start.upperBound..<end.lowerBound])
                } else {
                    print("invalid input")
                }
                alert_TextFieldCell.stringValue = "Jamf Cloud Status:\n\(statusLine2)"
                print("Jamf Cloud: \(statusLine2)")
            } else {
                alert_TextFieldCell.stringValue = ""
                print("status not found")
            }
            // try to capture status message from web page - end
            
            for theService in services {
                indexOfA = service.index(of: theService)
                if indexOfA != nil {
                    statusIndex = indexOfA!+1
                    while service[statusIndex!].trimmingCharacters(in: .whitespacesAndNewlines) != "<span class=\"component-status\">" {
                        statusIndex = statusIndex! + 1
                    }
                    statusIndex = statusIndex! + 1
                    print("\(theService)".trimmingCharacters(in: .whitespacesAndNewlines) + ": \(service[statusIndex!])")
                }
            }
            if statusPageString.lowercased().contains("all systems operational") {
                localResult = "cloudStatus-green"
                alert_ImageView.image = alert_image_green
                if alert_TextFieldCell.stringValue == "" {
                    alert_TextFieldCell.stringValue = "Jamf Cloud status is fully operational."
                }
                displayAlert(currentState: localResult)
                
            } else if statusPageString.lowercased().contains("page-status status-minor") || statusPageString.lowercased().contains("unresolved-incident impact-minor") {
                localResult = "cloudStatus-yellow"
                alert_ImageView.image = alert_image_yellow
                if alert_TextFieldCell.stringValue == "" {
                    alert_TextFieldCell.stringValue = "Please be aware there is a minor issue that may affect your Jamf Cloud instance."
                }
                displayAlert(currentState: localResult)
                
            } else if statusPageString.lowercased().contains("page-status status-maintenance") && statusPageString.lowercased().contains("experiencing issues with email services") {
                localResult = "cloudStatus-yellow"
                alert_ImageView.image = alert_image_yellow
                if alert_TextFieldCell.stringValue == "" {
                    alert_TextFieldCell.stringValue = "Please be aware there is a minor issue that should not affect your Jamf Cloud instance."
                }
                displayAlert(currentState: localResult)
                
            } else {
                localResult = "cloudStatus-red"
                alert_ImageView.image = alert_image_red
                if alert_TextFieldCell.stringValue == "" {
                    alert_TextFieldCell.stringValue = "Please be aware there is a major issue that may affect your Jamf Cloud instance."
                }
                displayAlert(currentState: localResult)
            }
            
            print("localResult2: \(localResult)\n")
        } catch let error {
            print("Error: \(error)")
        }
        
        return(localResult)
    }

}
