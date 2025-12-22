//
//  MyObserverClass.swift
//  jamfStatus
//
//  Created by leslie on 12/22/25.
//  Copyright © 2025 Leslie Helou. All rights reserved.
//

import AppKit
import Foundation

class MyObserverClass {
    private let appDelegate = AppDelegate()
    private var hasRegisteredObserver = false
       
   func setupObserver() {
       // Check if already registered
       guard !hasRegisteredObserver else {
           print("Observer already registered")
           return
       }
       
       DistributedNotificationCenter.default().addObserver(
           self,
           selector: #selector(interfaceModeChanged(sender:)),
           name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
           object: nil
       )
       
       hasRegisteredObserver = true
   }
   
   @objc func interfaceModeChanged(sender: Notification) {
       appDelegate.setTheme(darkMode: isDarkMode)
   }
   
   deinit {
       if hasRegisteredObserver {
           DistributedNotificationCenter.default().removeObserver(
               self,
               name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
               object: nil
           )
       }
   }
}
