//
//  CurrentHealthStatus.swift
//  jamfStatus
//
//  Created by leslie on 12/21/25.
//  Copyright © 2025 Leslie Helou. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class HealthStatusStore: ObservableObject {

    @Published private(set) var healthStatus: HealthStatus?

    static let shared = HealthStatusStore()

    private init() {}

    func update(from healthStatus: HealthStatus) {
        self.healthStatus = healthStatus
    }

    func clear() {
        self.healthStatus = nil
    }
}
