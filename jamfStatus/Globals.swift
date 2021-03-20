//
//  Globals.swift
//  jamfStatus
//
//  Created by Leslie Helou on 7/11/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Foundation

struct Log {
    static var path: String? = (NSHomeDirectory() + "/Library/Logs/jamfStatus/")
    static var file  = "jamfStatus.log"
    static var maxFiles = 10
    static var maxSize  = 500000 // 5MB
}
