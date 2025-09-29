//
//  MockBackoff.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 22/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockBackoff: BackoffPolicy {

    func backoff(forAttempt number: Int) -> Double {
        return Double(number)
    }
}
