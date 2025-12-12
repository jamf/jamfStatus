//
//  Copyright © 2025 Jamf. All rights reserved.
//

import TelemetryDeck

struct TelemetryDeckConfig {
    static let appId = "D766466B-CEA3-4E45-8792-0406D9E44A39"
    static var parameters: [String: String] = [:]
}

extension AppDelegate {
    @MainActor func configureTelemetryDeck() {
        
        let config = TelemetryDeck.Config(appID: TelemetryDeckConfig.appId)
        TelemetryDeck.initialize(config: config)
    }
}