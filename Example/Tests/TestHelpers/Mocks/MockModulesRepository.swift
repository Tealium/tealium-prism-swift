//
//  MockModulesRepository.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockModulesRepository: ModulesRepository {
    var onDataExpired: Observable<ExpiredDataEvent> = Observable.Just([
        1: [
            "key1": TealiumDataOutput(value: "")
        ],
        2: [
            "key2": TealiumDataOutput(value: "")
        ]
    ])
    func getModules() -> [String: Int64] {
        [:]
    }

    func registerModule(name: String) throws -> Int64 {
        1
    }

    func deleteExpired(expiry: ExpirationRequest) {

    }
}
