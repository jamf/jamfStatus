//
//  Preferences.swift
//  jamfStatus
//
//  Created by Leslie Helou on 4/21/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Cocoa

class Preferences: NSObject {
    var hideMenubarIcon: Bool? = false
    var hideUntilStatusChange: Bool? = true
    var launchAgent: Bool? = false
    var pollingInterval: Int? = 300
    var baseUrl: String? = "https://status.jamf.com"
    var jamfServerUrl = ""
    var username =  ""
    var password = ""
}


