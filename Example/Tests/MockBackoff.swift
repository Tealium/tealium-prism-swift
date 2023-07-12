//
//  MockBackoff.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 22/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import tealium_swift

class MockBackoff: BackoffPolicy {
    
    func backoff(forAttempt number: Int) -> Double {
        return Double(number)
    }
}
