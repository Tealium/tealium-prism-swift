//
//  RetainCycleHelper.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 05/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest

class RetainCycleHelper {
    private(set) var strongVariable: AnyObject?
    private(set) weak var weakVariable: AnyObject?

    init(variable: AnyObject?) {
        strongVariable = variable
        weakVariable = variable
    }

    func removeStrongReference() {
        strongVariable = nil
    }

    func forceAndAssertObjectDeinit(in file: StaticString = #file, line: UInt = #line) {
        removeStrongReference()
        XCTAssertNil(strongVariable, "The strong variable was removed by this helper")
        XCTAssertNil(weakVariable, "The weak variable should be automatically removed by ARC")
    }
}
