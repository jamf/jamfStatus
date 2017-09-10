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

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, URLSessionDelegate {

    @IBOutlet weak var cloudStatus_Toolbar: NSToolbar!
    @IBOutlet weak var cloudStatusWindow: NSWindow!
    @IBOutlet weak var page_WebView: WebView!
    @IBOutlet weak var prefs_Panel: NSPanel!
    @IBOutlet weak var pollingInterval_TextField: NSTextField!
    @IBOutlet weak var launchAgent_Button: NSButton!
    
    @IBOutlet weak var about_NSWindow: NSWindow!
    @IBOutlet weak var about_WebView: WKWebView!
    
    let fm = FileManager()
    let SMC = StatusMenuController()
    var pollingInterval: UInt32 = 300
    var hideIcon: Bool = false
    let launchAgentPath = NSHomeDirectory()+"/Library/LaunchAgents/com.jamf.cloudmonitor.plist"
    
    let popover = NSPopover()
    
    @IBAction func showAbout_MenuItem(_ sender: NSMenuItem) {
        
        let filePath = Bundle.main.path(forResource: "index", ofType: "html")
        let folderPath = Bundle.main.resourcePath
        
        let fileUrl = NSURL(fileURLWithPath: filePath!)
        let baseUrl = NSURL(fileURLWithPath: folderPath!, isDirectory: true)
        
        about_WebView.loadFileURL(fileUrl as URL, allowingReadAccessTo: baseUrl as URL)
        
        NSApplication.shared().activate(ignoringOtherApps: true)

        cloudStatusWindow.titleVisibility = NSWindowTitleVisibility.hidden
        about_NSWindow.setIsVisible(true)
    }
    
    
    @IBAction func viewStatus(_ sender: Any) {
        page_WebView.mainFrameURL = SMC.statusURL
        NSApplication.shared().activate(ignoringOtherApps: true)
        cloudStatusWindow.setIsVisible(true)
    }
    
    @IBOutlet weak var prefWindowAlerts_Button: NSButton!
    @IBOutlet weak var prefWindowIcon_Button: NSButton!
    
    @IBAction func prefs_MenuItem(_ sender: NSMenuItem) {
        let local_pollingInterval = SMC.readSettings()?["pollingInterval"]  as! Int32
        pollingInterval_TextField.stringValue = "\(local_pollingInterval)"
        
        let local_alertPrefs_bool = SMC.readSettings()?["hideUntilStatusChange"] as! Bool
        if local_alertPrefs_bool {
            prefWindowAlerts_Button.state = NSOnState
        } else {
            prefWindowAlerts_Button.state = NSOffState
        }
        let local_IconPrefs_bool = SMC.readSettings()?["hideMenubarIcon"] as! Bool
        if local_IconPrefs_bool {
            prefWindowIcon_Button.state = NSOnState
        } else {
            prefWindowIcon_Button.state = NSOffState
        }
        if (SMC.readSettings()?["launchAgent"]) != nil {
            let local_launchAgent_bool = SMC.readSettings()?["launchAgent"] as! Bool
            if local_launchAgent_bool {
                launchAgent_Button.state = NSOnState
            } else {
                launchAgent_Button.state = NSOffState
            }
        } else {
            launchAgent_Button.state = NSOffState
        }

        NSApplication.shared().activate(ignoringOtherApps: true)
        prefs_Panel.setIsVisible(true)
    }
    
    @IBAction func back_button(_ sender: Any) {
        page_WebView.goBack()
    }
    
    @IBAction func forward_button(_ sender: Any) {
        page_WebView.goForward()

    }
    
    func setDefaultPrefs () {
        let appPrefs = NSHomeDirectory()+"/Library/Preferences/com.jamf.jamfstatus.plist"
        if !fm.fileExists(atPath: appPrefs) {
            do {
                try fm.copyItem(atPath: Bundle.main.bundlePath+"/Contents/Resources/settings.plist", toPath: appPrefs)
            } catch {
                print("failed to write prefs")
            }
        }
    }
    
    @IBAction func writePrefs(_ sender: Any) {
        var isDir: ObjCBool = true
        pollingInterval = 300
        if let interval = UInt32(pollingInterval_TextField.stringValue) {
            if interval >= 60 {
                pollingInterval = interval
            }
        }
        SMC.settingsPlistData["pollingInterval"] = pollingInterval
        SMC.settingsPlistData["hideUntilStatusChange"] = (prefWindowAlerts_Button.state == 0 ? false:true)
        SMC.settingsPlistData["hideMenubarIcon"] = (prefWindowIcon_Button.state == 0 ? false:true)
        SMC.settingsPlistData["launchAgent"] = (launchAgent_Button.state == 0 ? false:true)
        
        if launchAgent_Button.state == 0 {
            if fm.fileExists(atPath: launchAgentPath) {
                do {
                    try fm.removeItem(atPath: launchAgentPath)
                } catch {
                    print("failed to remove LaunchAgent")
                }
            }
        } else {
            if !fm.fileExists(atPath: launchAgentPath) {
                do {
                    if !(fm.fileExists(atPath: NSHomeDirectory() + "/Library/LaunchAgents", isDirectory: &isDir)) {
                        do {
                            try fm.createDirectory(atPath: NSHomeDirectory() + "/Library/LaunchAgents", withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            NSLog("Problem creating '/Library/LaunchAgents' folder:  \(error)")
                        }
                    }
                    try fm.copyItem(atPath: Bundle.main.bundlePath+"/Contents/Resources/com.jamf.cloudmonitor.plist", toPath: launchAgentPath)
                } catch {
                    print("failed to write LaunchAgent")
                }
            }
        }
        // Write info to settings.plist
        (SMC.settingsPlistData as NSDictionary).write(toFile: SMC.SettingsPlistPath, atomically: false)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }



}

