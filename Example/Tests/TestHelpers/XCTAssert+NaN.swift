//
//  XCTAssert+NaN.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 30/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest

func XCTAssertNaN(_ value: Double?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrueOptional(value?.isNaN, "Value \(String(describing: value)) is not NaN", file: file, line: line)
}

func XCTAssertNotNaN(_ value: Double?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertFalseOptional(value?.isNaN, "Value \(String(describing: value)) is not NaN", file: file, line: line)
}
