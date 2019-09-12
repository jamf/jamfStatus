//
//  NotificationAlerts.swift
//  jamfStatus
//
//  Created by Leslie Helou on 9/2/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

class NotificationAlert {
    var title: String
    var params: Dictionary<String, Any>

    init(title: String) {
        self.title = title
        self.params = [:]
    }
}
