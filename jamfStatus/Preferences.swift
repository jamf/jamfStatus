//
//  Preferences.swift
//  jamfStatus
//
//  Created by Leslie Helou on 4/21/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

struct Preferences {
    static var hideMenubarIcon: Bool?       = false
    static var hideUntilStatusChange: Bool? = true
    static var launchAgent: Bool?           = false
    static var pollingInterval: Int?        = 300
    static var baseUrl: String?             = "https://status.jamf.com"
    static var jamfServerUrl                = ""
    static var username                     = ""
    static var password                     = ""
    static var menuIconStyle                = "color"
}


