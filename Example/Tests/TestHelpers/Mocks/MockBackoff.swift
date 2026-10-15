//
//  MockBackoff.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 22/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

extension Backoff {
    /// Uses the retry count, in seconds, as the delay.
    static let retryCount = Backoff { Double($0) }

    /// Always returns `delay`, regardless of the retry count.
    static func fixed(_ delay: TimeInterval) -> Backoff {
        Backoff { _ in delay }
    }
}
