//
//  DeinitTester.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class DeinitTester {
    var onDeinit: (() -> Void)

    init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
    }
}
