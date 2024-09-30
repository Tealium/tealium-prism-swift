//
//  XCTAssert+NSNull.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 30/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest

func XCTAssertNSNull(_ value: Any?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(value is NSNull, "Value \(String(describing: value)) is not NSNull", file: file, line: line)
}

func XCTAssertNotNSNull(_ value: Any?, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertFalse(value is NSNull, "Value \(String(describing: value)) is NSNull", file: file, line: line)
}
