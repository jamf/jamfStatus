//
//  Copyright 2025, Jamf
//

import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    static let check = Logger(subsystem: subsystem, category: "check")
    static let token = Logger(subsystem: subsystem, category: "token")
}
