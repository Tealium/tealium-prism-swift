//
//  XCTAssertEqualDictionaries.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest

func XCTAssertEqual(
    _ lhs: [String: Any]?,
    _ rhs: [String: Any]?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(lhs as? NSDictionary, rhs as? NSDictionary, file: file, line: line)
}

func XCTAssertNotEqual(
    _ lhs: [String: Any]?,
    _ rhs: [String: Any]?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNotEqual(lhs as? NSDictionary, rhs as? NSDictionary, file: file, line: line)
}
