//
//  XCTAssert+NaN.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 30/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest

func XCTAssertNaN(_ value: Decimal?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrueOptional(value?.isNaN, "Value \(String(describing: value)) is not NaN", file: file, line: line)
}

func XCTAssertNotNaN(_ value: Decimal?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertFalseOptional(value?.isNaN, "Value \(String(describing: value)) is not NaN", file: file, line: line)
}

func XCTAssertNaN(_ value: Float?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNaN(value.map { Double($0) }, file: file, line: line)
}

func XCTAssertNotNaN(_ value: Float?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNotNaN(value.map { Double($0) }, file: file, line: line)
}

func XCTAssertNaN(_ value: Double?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNaN(value.map { Decimal($0) }, file: file, line: line)
}

func XCTAssertNotNaN(_ value: Double?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNotNaN(value.map { Decimal($0) }, file: file, line: line)
}
