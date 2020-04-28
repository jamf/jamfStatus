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
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var cloudStatus_Toolbar: NSToolbar!
    @IBOutlet weak var cloudStatusWindow: NSWindow!
    
    @IBOutlet var page_WebView: WKWebView!
    @IBOutlet weak var prefs_Panel: NSPanel!
    
    
    @IBOutlet weak var pollingInterval_TextField: NSTextField!
    @IBOutlet weak var launchAgent_Button: NSButton!
    @IBOutlet weak var iconStyle_Button: NSPopUpButton!
    

    // site specific settings
    @IBOutlet weak var jamfServerUrl_TextField: NSTextField!
    @IBOutlet weak var username_TextField: NSTextField!
    @IBOutlet weak var password_TextField: NSSecureTextField!
    
    @IBOutlet weak var siteConnectionStatus_ImageView: NSImageView!
    let statusImage:[NSImage] = [NSImage(named: "red-dot")!,
                                 NSImage(named: "green-dot")!]
    
    //    @IBOutlet weak var monitorUrl_TextField: NSTextField!
    
    @IBOutlet weak var about_NSWindow: NSWindow!
    @IBOutlet weak var about_WebView: WKWebView!
    
    let prefs = Preferences.self
    let defaults = UserDefaults()
    
    let fm = FileManager()
    var pollingInterval: Int = 300
    var hideIcon: Bool = false
    let launchAgentPath = NSHomeDirectory()+"/Library/LaunchAgents/com.jamf.cloudmonitor.plist"
    
    //    let popover = NSPopover()
    
    @IBAction func iconStyle_Action(_ sender: Any) {
        if iconStyle_Button.indexOfSelectedItem == 0 {
            prefs.menuIconStyle = "color"
        } else {
            prefs.menuIconStyle = "slash"
        }
        defaults.set(prefs.menuIconStyle, forKey: "menuIconStyle")
    }
    
    
    @IBAction func showAbout_MenuItem(_ sender: NSMenuItem) {
        
        let filePath = Bundle.main.path(forResource: "index", ofType: "html")
        let folderPath = Bundle.main.resourcePath
        
        let fileUrl = NSURL(fileURLWithPath: filePath!)
        let baseUrl = NSURL(fileURLWithPath: folderPath!, isDirectory: true)
        
        about_WebView.loadFileURL(fileUrl as URL, allowingReadAccessTo: baseUrl as URL)
        
        //        cloudStatusWindow.titleVisibility = NSWindow.TitleVisibility.hidden
//        about_NSWindow.setIsVisible(true)
        showOnActiveScreen(windowName: about_NSWindow, panelName: prefs_Panel, type: "window")
        
    }
    
    @IBAction func checkForUpdates(_ sender: AnyObject) {
        let verCheck = VersionCheck()
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        verCheck.versionCheck() {
            (result: Bool) in
            if result {
                self.alert_dialog(header: "Running jamfStatus: \(version)", message: "A new versions is available.", updateAvail: result)
            } else {
                self.alert_dialog(header: "Running jamfStatus: \(version)", message: "No updates are currently available.", updateAvail: result)
            }
        }
    }
    
    @IBAction func viewStatus(_ sender: Any) {

        DispatchQueue.main.async {
            if let url = URL(string: "https://status.jamf.com") {
                let request = URLRequest(url: url)
                
                self.page_WebView?.load(request)

            }
            self.cloudStatusWindow.titleVisibility = .hidden
            
            self.showOnActiveScreen(windowName: self.cloudStatusWindow, panelName: self.prefs_Panel, type: "window")
//            NSApplication.shared.activate(ignoringOtherApps: true)
//            self.cloudStatusWindow.setIsVisible(true)
        }
    }
    
    @IBOutlet weak var prefWindowAlerts_Button: NSButton!
    @IBOutlet weak var prefWindowIcon_Button: NSButton!
    
    @IBAction func prefs_MenuItem(_ sender: NSMenuItem) {
        showPrefsWindow()
    }
    
    // actions for preferences window - start
    @IBAction func pollInterval_Action(_ sender: NSTextField) {
        prefs.pollingInterval = Int(pollingInterval_TextField.stringValue) ?? 0
        if prefs.pollingInterval! < 60 {
            prefs.pollingInterval = 300
            pollingInterval_TextField.stringValue = "300"
        }
        defaults.set(prefs.pollingInterval, forKey: "pollingInterval")
        defaults.synchronize()
        prefs.pollingInterval = defaults.object(forKey: "pollingInterval") as? Int
    }
    @IBAction func prefWindowAlerts_Action(_ sender: NSButton) {
//        print("sender: \(String(describing: sender.identifier?.rawValue))")
//        if ("\(String(describing: sender.identifier?.rawValue))" == "_NS:18") {
//
//        }
        prefs.hideUntilStatusChange = (prefWindowAlerts_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.hideUntilStatusChange, forKey: "hideUntilStatusChange")
        defaults.synchronize()
    }
    @IBAction func hideMenubarIcon_Action(_ sender: NSButton) {
        prefs.hideMenubarIcon = (prefWindowIcon_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.hideMenubarIcon, forKey: "hideMenubarIcon")
        defaults.synchronize()
    }
    @IBAction func launchAgent_Action(_ sender: NSButton) {
        var isDir: ObjCBool = true
        prefs.launchAgent = (launchAgent_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.launchAgent, forKey: "launchAgent")
        defaults.synchronize()
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
    
    @IBAction func credentials_Action(_ sender: Any) {
        
        prefs.jamfServerUrl = jamfServerUrl_TextField.stringValue
        defaults.set(prefs.jamfServerUrl, forKey: "jamfServerUrl")
        defaults.synchronize()
        
        prefs.username = username_TextField.stringValue
        
        prefs.password = password_TextField.stringValue
        
//        let urlRegex = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
//        let serverFqdn = urlRegex.stringByReplacingMatches(in: prefs.jamfServerUrl, options: [], range: NSRange(0..<prefs.jamfServerUrl.utf16.count), withTemplate: "")
//        print("server: \(serverFqdn), username: \(prefs.username), password: \(prefs.password)")
        saveCreds(server: prefs.jamfServerUrl, username: prefs.username, password: prefs.password)
    }
    
    // actions for preferences window - start
    
    @IBAction func back_button(_ sender: Any) {
        page_WebView.goBack()
    }
    
    @IBAction func forward_button(_ sender: Any) {
        page_WebView.goForward()
        
    }
    
    func alert_dialog(header: String, message: String, updateAvail: Bool) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.informational
        if updateAvail {
            dialog.addButton(withTitle: "View")
            dialog.addButton(withTitle: "Ignore")
        } else {
            dialog.addButton(withTitle: "OK")
        }
        
        let clicked:NSApplication.ModalResponse = dialog.runModal()
        
        if clicked.rawValue == 1000 && updateAvail {
            if let url = URL(string: "https://github.com/jamf/jamfStatus/releases") {
                NSWorkspace.shared.open(url)
            }
        }
        
        //return true
    }   // func alert_dialog - end
    
    func saveCreds(server: String, username: String, password: String) {
        if ( server != "" && username != "" && password != "" ) {
            
            let urlRegex = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
            let serverFqdn = urlRegex.stringByReplacingMatches(in: server, options: [], range: NSRange(0..<server.utf16.count), withTemplate: "")
            
            let b64creds = ("\(username):\(password)".data(using: .utf8)?.base64EncodedString())!
            
            // update the connection indicator for the site server
            UapiCall().token(serverUrl: server, creds: b64creds) {
                (returnedToken: String) in
                if returnedToken != "" {
//                    print("authentication verified")
                    DispatchQueue.main.async {
                        self.siteConnectionStatus_ImageView.image = self.statusImage[1]
                    }
                    Credentials2().save(service: "jamfStatus: \(serverFqdn)", account: username, data: password)
                } else {
                    print("authentication failed")
                    DispatchQueue.main.async {
                        self.siteConnectionStatus_ImageView.image = self.statusImage[0]
                    }
                }
            } // UapiCall().token - end
        }
    }
    
    func showPrefsWindow() {
        pollingInterval_TextField.stringValue = "\(String(describing: defaults.object(forKey:"pollingInterval")!))"

        prefWindowAlerts_Button.state = NSControl.StateValue.on

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
        
        let menuIcon = defaults.string(forKey: "menuIconStyle") ?? prefs.menuIconStyle
        if menuIcon == "color" {
            iconStyle_Button.selectItem(at: 0)
        } else {
            iconStyle_Button.selectItem(at: 1)
        }
        
        let serverUrl = defaults.string(forKey:"jamfServerUrl") ?? ""
        if serverUrl != "" {
            jamfServerUrl_TextField.stringValue = serverUrl
            let urlRegex = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
            let serverFqdn = urlRegex.stringByReplacingMatches(in: serverUrl, options: [], range: NSRange(0..<serverUrl.utf16.count), withTemplate: "")

            let credentialsArray = Credentials2().retrieve(service: "jamfStatus: \(serverFqdn)")
            if credentialsArray.count == 2 {
                prefs.username = credentialsArray[0]
                prefs.password = credentialsArray[1]
                username_TextField.stringValue = credentialsArray[0]
                password_TextField.stringValue = credentialsArray[1]
            } else {
                prefs.username = ""
                prefs.password = ""
            }
        }
        
        saveCreds(server: serverUrl, username: prefs.username, password: prefs.password)
        showOnActiveScreen(windowName: about_NSWindow, panelName: prefs_Panel, type: "panel")

    }
    
    func showOnActiveScreen(windowName: NSWindow, panelName: NSPanel, type: String) {
        
        var xPos = 0.0
        var yPos = 0.0
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        switch type {
        case "window":
            if let screen = NSScreen.main {
                let currentFrameWidth = Double(screen.frame.width)
                let currentFrameHeight = Double(screen.frame.height)
                let windowWidth = Double(windowName.frame.width)
                let windowHeight = Double(windowName.frame.height)
                xPos = currentFrameWidth - windowWidth + Double(screen.frame.origin.x) - 20.0
                yPos = currentFrameHeight - windowHeight + Double(screen.frame.origin.y) - 40.0
            }
            windowName.collectionBehavior = NSWindow.CollectionBehavior.moveToActiveSpace
            windowName.makeKeyAndOrderFront(self)
            windowName.setFrameOrigin(NSPoint(x: xPos, y: yPos))
            DispatchQueue.main.async {
                windowName.setIsVisible(true)
                //                places window in bottom left corner of screen
                //                self.notifier_window.setFrameOrigin(NSPoint(x: 0, y: 0))
            }
        default:
            if let screen = NSScreen.main {
                let currentFrameWidth = Double(screen.frame.width)
                let currentFrameHeight = Double(screen.frame.height)
                //            print("dimensions: \(currentFrameWidth) x \(currentFrameHeight)\n")
                let windowWidth = Double(prefs_Panel.frame.width)
                let windowHeight = Double(prefs_Panel.frame.height)
                xPos = currentFrameWidth - windowWidth + Double(screen.frame.origin.x) - 20.0
                yPos = currentFrameHeight - windowHeight + Double(screen.frame.origin.y) - 40.0
            }
            panelName.collectionBehavior = NSWindow.CollectionBehavior.moveToActiveSpace
            panelName.makeKeyAndOrderFront(self)
            panelName.setFrameOrigin(NSPoint(x: xPos, y: yPos))
            DispatchQueue.main.async {
                panelName.setIsVisible(true)
            }
        }
        
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

