//
//  MockModulesRepository.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockModulesRepository: ModulesRepository {

    @Subject<ExpiredDataEvent> var onDataExpired
    func getModules() -> [String: Int64] {
        [:]
    }

    func registerModule(name: String) throws -> Int64 {
        1
    }

    func deleteExpired(expiry: ExpirationRequest) {

    }

    func expire(_ event: ExpiredDataEvent) {
        _onDataExpired.publish(event)
    }
}
