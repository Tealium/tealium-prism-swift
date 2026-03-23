//
//  StringUtilsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class StringUtilsTests: XCTestCase {

    func test_string_with_only_whitespaces_is_blank() {
        XCTAssertTrue(StringUtils.isBlank(" "))
    }

    func test_string_with_only_new_lines_is_blank() {
        XCTAssertTrue(StringUtils.isBlank("\n"))
    }

    func test_string_with_only_new_lines_and_whitespaces_is_blank() {
        XCTAssertTrue(StringUtils.isBlank("\n \n "))
    }

    func test_empty_string_is_blank() {
        XCTAssertTrue(StringUtils.isBlank(""))
    }

    func test_string_with_characters_is_not_blank() {
        XCTAssertFalse(StringUtils.isBlank("Some string"))
    }
}
