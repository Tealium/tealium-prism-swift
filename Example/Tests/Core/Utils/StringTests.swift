//
//  StringTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class StringTests: XCTestCase {

    func test_string_with_only_whitespaces_is_blank() {
        XCTAssertTrue(" ".isBlank)
    }

    func test_string_with_only_new_lines_is_blank() {
        XCTAssertTrue("\n".isBlank)
    }

    func test_string_with_only_new_lines_and_whitespaces_is_blank() {
        XCTAssertTrue("\n \n ".isBlank)
    }

    func test_empty_string_is_blank() {
        XCTAssertTrue("".isBlank)
    }

    func test_string_with_characters_is_not_blank() {
        XCTAssertFalse("Some string".isBlank)
    }
}
