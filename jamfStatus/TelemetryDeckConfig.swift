//
//  Copyright © 2025 Jamf. All rights reserved.
//

import TelemetryDeck

struct TelemetryDeckConfig {
    static let appId = "D1FAAD0B-60F6-44F6-94AF-BBF0194B5EFF"
    static var parameters: [String: String] = [:]
}

extension StatusMenuController {
    @MainActor func configureTelemetryDeck() {
        let config = TelemetryDeck.Config(appID: TelemetryDeckConfig.appId)
        TelemetryDeck.initialize(config: config)
    }
}
