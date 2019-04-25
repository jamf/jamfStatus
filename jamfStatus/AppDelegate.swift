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
class AppDelegate: NSObject, NSApplicationDelegate, URLSessionDelegate, URLSessionTaskDelegate {
    
    @IBOutlet weak var cloudStatus_Toolbar: NSToolbar!
    @IBOutlet weak var cloudStatusWindow: NSWindow!
    
    @IBOutlet var page_WebView: WKWebView!
    @IBOutlet weak var prefs_Panel: NSPanel!
    @IBOutlet weak var pollingInterval_TextField: NSTextField!
    @IBOutlet weak var launchAgent_Button: NSButton!
    
    //    @IBOutlet weak var monitorUrl_TextField: NSTextField!
    
    
    @IBOutlet weak var about_NSWindow: NSWindow!
    @IBOutlet weak var about_WebView: WKWebView!
    
    let prefs = Preferences()
    let defaults = UserDefaults()
    
    let fm = FileManager()
    let SMC = StatusMenuController()
    var pollingInterval: Int = 300
    var hideIcon: Bool = false
    let launchAgentPath = NSHomeDirectory()+"/Library/LaunchAgents/com.jamf.cloudmonitor.plist"
    
    //    let popover = NSPopover()
    
    @IBAction func showAbout_MenuItem(_ sender: NSMenuItem) {
        
        let filePath = Bundle.main.path(forResource: "index", ofType: "html")
        let folderPath = Bundle.main.resourcePath
        
        let fileUrl = NSURL(fileURLWithPath: filePath!)
        let baseUrl = NSURL(fileURLWithPath: folderPath!, isDirectory: true)
        
        about_WebView.loadFileURL(fileUrl as URL, allowingReadAccessTo: baseUrl as URL)
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
//        cloudStatusWindow.titleVisibility = NSWindow.TitleVisibility.hidden
        about_NSWindow.setIsVisible(true)
    }
    
    @IBAction func viewStatus(_ sender: Any) {

        DispatchQueue.main.async {
            if let url = URL(string: "https://status.jamf.com") {
                let request = URLRequest(url: url)
                
                self.page_WebView?.load(request)

            }
            self.cloudStatusWindow.titleVisibility = .hidden
            NSApplication.shared.activate(ignoringOtherApps: true)
            self.cloudStatusWindow.setIsVisible(true)
        }
    }
    
    @IBOutlet weak var prefWindowAlerts_Button: NSButton!
    @IBOutlet weak var prefWindowIcon_Button: NSButton!
    
    @IBAction func prefs_MenuItem(_ sender: NSMenuItem) {
        pollingInterval_TextField.stringValue = "\(String(describing: defaults.object(forKey:"pollingInterval")!))"
        
        if (defaults.bool(forKey: "hideUntilStatusChange")) {
            prefWindowAlerts_Button.state = NSControl.StateValue.on
        } else {
            prefWindowAlerts_Button.state = NSControl.StateValue.off
        }
        if (defaults.bool(forKey: "hideMenubarIcon")) {
            prefWindowIcon_Button.state = NSControl.StateValue.on
        } else {
            prefWindowIcon_Button.state = NSControl.StateValue.off
        }
        if (defaults.bool(forKey: "launchAgent")) {
            launchAgent_Button.state = NSControl.StateValue.on
        } else {
            launchAgent_Button.state = NSControl.StateValue.off
        }
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        prefs_Panel.setIsVisible(true)
    }
    
    // actions for preferences window - start
    @IBAction func pollInterval_Action(_ sender: NSTextField) {
        prefs.pollingInterval = Int(pollingInterval_TextField.stringValue)
        if prefs.pollingInterval! < 60 {
            prefs.pollingInterval = 300
        }
        defaults.set(prefs.pollingInterval, forKey: "pollingInterval")
        prefs.pollingInterval = defaults.object(forKey: "pollingInterval") as? Int
    }
    @IBAction func prefWindowAlerts_Action(_ sender: NSButton) {
//        print("sender: \(String(describing: sender.identifier?.rawValue))")
//        if ("\(String(describing: sender.identifier?.rawValue))" == "_NS:18") {
//
//        }
        prefs.hideUntilStatusChange = (prefWindowAlerts_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.hideUntilStatusChange, forKey: "hideUntilStatusChange")
    }
    @IBAction func hideMenubarIcon_Action(_ sender: NSButton) {
        prefs.hideMenubarIcon = (prefWindowIcon_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.hideMenubarIcon, forKey: "hideMenubarIcon")
    }
    @IBAction func launchAgent_Action(_ sender: NSButton) {
        var isDir: ObjCBool = true
        prefs.launchAgent = (launchAgent_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.launchAgent, forKey: "launchAgent")
        if launchAgent_Button.state.rawValue == 0 {
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
    }
    
    // actions for preferences window - start
    
    @IBAction func back_button(_ sender: Any) {
        page_WebView.goBack()
    }
    
    @IBAction func forward_button(_ sender: Any) {
        page_WebView.goForward()
        
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

