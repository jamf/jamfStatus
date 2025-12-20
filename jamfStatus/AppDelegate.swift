//AppDelegate.swift
//Author: Leslie Helou
//Copyright 2017 Jamf Professional Services
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, URLSessionDelegate {
    
    @IBOutlet weak var cloudStatus_Toolbar: NSToolbar!
    @IBOutlet weak var cloudStatusWindow: NSWindow!
    
    @IBOutlet var page_WebView: WKWebView!
    @IBOutlet weak var prefs_Window: NSWindow!
    @IBOutlet weak var aboutVersion_TextField: NSTextField!
    @IBOutlet weak var aboutHomeUrl_Button: NSButton!
    
    
    @IBOutlet weak var pollingInterval_TextField: NSTextField!
    @IBOutlet weak var launchAgent_Button: NSButton!
    @IBOutlet weak var iconStyle_Button: NSPopUpButton!
    

    // site specific settings
    @IBOutlet weak var jamfServerUrl_TextField: NSTextField!
    @IBOutlet weak var username_Label: NSTextField!
    @IBOutlet weak var password_Label: NSTextField!
    @IBOutlet weak var username_TextField: NSTextField!
    @IBOutlet weak var password_TextField: NSSecureTextField!
    @IBOutlet weak var useApiClient_button: NSButton!
    @IBAction func useApiClient_action(_ sender: NSButton) {
        useApiClient = useApiClient_button.state.rawValue
        defaults.set(useApiClient_button.state.rawValue, forKey: "useApiClient")
        setLabels()
        fetchPassword()
    }
    
    @IBOutlet weak var siteConnectionStatus_ImageView: NSImageView!
    let statusImage:[NSImage] = [NSImage(named: "red-dot")!,
                                 NSImage(named: "green-dot")!]
        
    @IBOutlet weak var about_NSWindow: NSWindow!
    @IBOutlet weak var about_WebView: WKWebView!
    
    let prefs = Preferences.self
    let defaults = UserDefaults()
    
    let fm = FileManager()
    var pollingInterval: Int = 300
    var hideIcon: Bool = false
    let launchAgentPath = NSHomeDirectory()+"/Library/LaunchAgents/com.jamf.cloudmonitor.plist"
    
    @objc func notificationsAction(_ sender: NSMenuItem) {
//        print("\(sender.identifier!.rawValue)")
//        WriteToLog().message(stringOfText: ["\(sender.identifier!.rawValue)"])
    }
    
    
    @IBAction func iconStyle_Action(_ sender: Any) {
        if iconStyle_Button.indexOfSelectedItem == 0 {
            prefs.menuIconStyle = "color"
        } else {
            prefs.menuIconStyle = "slash"
        }
        defaults.set(prefs.menuIconStyle, forKey: "menuIconStyle")
    }
    
    
    @IBAction func showAbout_MenuItem(_ sender: NSMenuItem) {
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        let filePath = Bundle.main.path(forResource: "index", ofType: "html")
        let folderPath = Bundle.main.resourcePath
//        
        let fileUrl = NSURL(fileURLWithPath: filePath!)
        let baseUrl = NSURL(fileURLWithPath: folderPath!, isDirectory: true)
        
        about_WebView.loadFileURL(fileUrl as URL, allowingReadAccessTo: baseUrl as URL)

        aboutVersion_TextField.stringValue = "Version: \(version)"
        
        let stringAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: NSColor.systemBlue]
        let attributedTitle = NSAttributedString(string: "Home", attributes: stringAttributes)
        aboutHomeUrl_Button.attributedTitle = attributedTitle
        aboutHomeUrl_Button.toolTip = "https://github.com/jamf/jamfStatus"
        
        showOnActiveScreen(windowName: about_NSWindow)
        
    }
    @IBAction func aboutHomeUrl_Button(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(string: "https://github.com/jamf/jamfStatus")!)
    }
    
    @IBAction func checkForUpdates(_ sender: AnyObject) {
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        VersionCheck().versionCheck() {
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
            
            self.showOnActiveScreen(windowName: self.cloudStatusWindow)
        }
    }
    
    @IBOutlet weak var prefWindowAlerts_Button: NSButton!
    @IBOutlet weak var prefWindowIcon_Button: NSButton!
    
    @IBAction func prefs_MenuItem(_ sender: NSMenuItem) {
        setLabels()
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
//        defaults.synchronize()
        prefs.pollingInterval = defaults.object(forKey: "pollingInterval") as? Int
    }
    @IBAction func prefWindowAlerts_Action(_ sender: NSButton) {
//        print("sender: \(String(describing: sender.identifier?.rawValue))")
        prefs.hideUntilStatusChange = (prefWindowAlerts_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.hideUntilStatusChange, forKey: "hideUntilStatusChange")
//        defaults.synchronize()
    }
    @IBAction func hideMenubarIcon_Action(_ sender: NSButton) {
        prefs.hideMenubarIcon = (prefWindowIcon_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.hideMenubarIcon, forKey: "hideMenubarIcon")
//        defaults.synchronize()
    }
    @IBAction func launchAgent_Action(_ sender: NSButton) {
        var isDir: ObjCBool = true
        prefs.launchAgent = (launchAgent_Button.state.rawValue == 0 ? false:true)
        defaults.set(prefs.launchAgent, forKey: "launchAgent")
//        defaults.synchronize()
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
        JamfProServer.url = jamfServerUrl_TextField.stringValue
        
        let urlRegex = try! NSRegularExpression(pattern: "/?failover(.*?)", options:.caseInsensitive)
        JamfProServer.url = urlRegex.stringByReplacingMatches(in: JamfProServer.url, options: [], range: NSRange(0..<JamfProServer.url.utf16.count), withTemplate: "")
        
        defaults.set(JamfProServer.url, forKey: "jamfServerUrl")
//        defaults.synchronize()
        
        JamfProServer.username = username_TextField.stringValue
        JamfProServer.password = password_TextField.stringValue
        
        saveCreds(server: JamfProServer.url, username: JamfProServer.username, password: JamfProServer.password)
    }
    
    // actions for preferences window - start
    
    func fetchPassword() {
        let credentialsArray = Credentials().itemLookup(service: jamfServerUrl_TextField.stringValue.fqdnFromUrl)
        if credentialsArray.count == 2 {
            username_TextField.stringValue = credentialsArray[0]
            password_TextField.stringValue = credentialsArray[1]
        } else {
            password_TextField.stringValue = ""
        }
    }
    
    func setLabels() {
        useApiClient = defaults.integer(forKey: "useApiClient")
        if useApiClient == 0 {
            username_Label.stringValue = "Username:"
            password_Label.stringValue = "Password:"
        } else {
            username_Label.stringValue = "Client ID:"
            password_Label.stringValue = "Secret:"
        }
    }
    
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
    }   // func alert_dialog - end

    func saveCreds(server: String, username: String, password: String) {
        if ( server != "" && username != "" && password != "" ) {
            
            let urlRegex = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
            let serverFqdn = urlRegex.stringByReplacingMatches(in: server, options: [], range: NSRange(0..<server.utf16.count), withTemplate: "")
            
            JamfProServer.base64Creds = ("\(username):\(password)".data(using: .utf8)?.base64EncodedString())!
            token.isValid = false
            // update the connection indicator for the site server
            TokenDelegate().getToken(serverUrl: server, base64creds: JamfProServer.base64Creds) {
                (authResult: (Int,String)) in
                            
                if authResult.1 == "success" {
//                    print("authentication verified")
                    DispatchQueue.main.async {
                        self.siteConnectionStatus_ImageView.image = self.statusImage[1]
                    }
                    Credentials().save(service: server.fqdnFromUrl, account: username, data: password)
                } else {
                    print("authentication failed")
                    DispatchQueue.main.async {
                        self.siteConnectionStatus_ImageView.image = self.statusImage[0]
                    }
                }
                self.siteConnectionStatus_ImageView.isHidden = false
            } // JamfPro().getToken(serverUrl - end
        }
    }
    
    func showPrefsWindow() {
        self.siteConnectionStatus_ImageView.isHidden = true
        pollingInterval_TextField.stringValue = "\(String(describing: defaults.object(forKey:"pollingInterval")!))"

        prefWindowAlerts_Button.state = NSControl.StateValue.on
        
        useApiClient_button.state =  NSControl.StateValue(rawValue: defaults.integer(forKey: "useApiClient"))

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

            let credentialsArray = Credentials().itemLookup(service: serverUrl.fqdnFromUrl)
            if credentialsArray.count == 2 {
                JamfProServer.username = credentialsArray[0]
                JamfProServer.password = credentialsArray[1]
                username_TextField.stringValue = credentialsArray[0]
                password_TextField.stringValue = credentialsArray[1]
            } else {
                JamfProServer.username = ""
                JamfProServer.password = ""
            }
        }
        
        saveCreds(server: serverUrl, username: JamfProServer.username, password: JamfProServer.password)
        showOnActiveScreen(windowName: prefs_Window)

    }
    
    func showOnActiveScreen(windowName: NSWindow) {
        
        var xPos = 0.0
        var yPos = 0.0
           
        if let screen = NSScreen.main {
            let currentFrameWidth = Double(screen.frame.width)
            let currentFrameHeight = Double(screen.frame.height)
            let windowWidth = Double(windowName.frame.width)
            let windowHeight = Double(windowName.frame.height)
            xPos = currentFrameWidth - windowWidth + Double(screen.frame.origin.x) - 20.0
            yPos = currentFrameHeight - windowHeight + Double(screen.frame.origin.y) - 40.0
        }
//            windowName.collectionBehavior = NSWindow.CollectionBehavior.moveToActiveSpace
        windowName.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        windowName.setIsVisible(true)
                
        windowName.orderFrontRegardless()
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

