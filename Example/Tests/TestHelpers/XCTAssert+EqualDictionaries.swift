//
//  XCTAssertEqualDictionaries.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift
import XCTest

func XCTAssertEqual(
    _ lhs: [String: Any?]?,
    _ rhs: [String: Any?]?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(lhs as? NSDictionary, rhs as? NSDictionary, file: file, line: line)
}

func XCTAssertNotEqual(
    _ lhs: [String: Any?]?,
    _ rhs: [String: Any?]?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNotEqual(lhs as? NSDictionary, rhs as? NSDictionary, file: file, line: line)
}

func XCTAssertEqual(
    _ lhs: [Any?]?,
    _ rhs: [Any?]?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(lhs as? NSArray, rhs as? NSArray, file: file, line: line)
}

func XCTAssertNotEqual(
    _ lhs: [Any?]?,
    _ rhs: [Any?]?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNotEqual(lhs as? NSArray, rhs as? NSArray, file: file, line: line)
}

extension DataObject: Equatable {
    public static func == (lhs: DataObject, rhs: DataObject) -> Bool {
        lhs.asDictionary() == rhs.asDictionary()
    }
}

func XCTAssertEqual(
    _ lhs: SDKSettings?,
    _ rhs: SDKSettings?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(lhs?.modulesSettings, rhs?.modulesSettings, file: file, line: line)
}

func XCTAssertNotEqual(
    _ lhs: SDKSettings?,
    _ rhs: SDKSettings?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNotEqual(lhs?.modulesSettings, rhs?.modulesSettings, file: file, line: line)
}
