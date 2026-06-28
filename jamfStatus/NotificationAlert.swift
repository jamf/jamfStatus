//
//  NotificationAlerts.swift
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
