//
//  HealthStatus.swift
//  Wallpaper
//
//  Created by leslie on 7/2/25.
//

import Foundation

final class HealthStatus: Codable {
    let api, ui, enrollment, device, healthStatusDefault: API

    enum CodingKeys: String, CodingKey {
        case api, ui, enrollment, device
        case healthStatusDefault = "default"
    }
    
    init(api: API, ui: API, enrollment: API, device: API, healthStatusDefault: API) {
        self.api = api
        self.ui = ui
        self.enrollment = enrollment
        self.device = device
        self.healthStatusDefault = healthStatusDefault
    }
}

final class API: Codable {
    let thirtySeconds, oneMinute, fiveMinutes, fifteenMinutes, thirtyMinutes: Double
    
    init(thirtySeconds: Double, oneMinute: Double, fiveMinutes: Double, fifteenMinutes: Double, thirtyMinutes: Double) {
        self.thirtySeconds = thirtySeconds
        self.oneMinute = oneMinute
        self.fiveMinutes = fiveMinutes
        self.fifteenMinutes = fifteenMinutes
        self.thirtyMinutes = thirtyMinutes
    }
}

enum HealthStatusError: Error {
    case authenticationFailed
    case invalidResponse
}
