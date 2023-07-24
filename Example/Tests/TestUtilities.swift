//
//  TestUtilities.swift
//  tealium-swift_Tests
//
//  Created by Tyler Rister on 6/22/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest

struct UnexpectedNilError: LocalizedError, CustomStringConvertible {
    var description: String {
        return "Unexpectedly found nil but expected: \(expected)"
    }
    
    let expected: Any
    init(expected: Any) {
        self.expected = expected
    }
}

extension XCTestCase {
    
    func XCTAssertFalseOptional(_ expression: @autoclosure () throws -> Bool?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line){
        XCTAssertFalse(try notNil(expression(), expected: false),
                       message(),
                       file: file,
                       line: line)
    }
    
    func XCTAssertTrueOptional(_ expression: @autoclosure () throws -> Bool?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line){
        XCTAssertTrue(try notNil(expression(), expected: true),
                       message(),
                       file: file,
                       line: line)
    }
    
    
    func notNil(_ expression: @autoclosure () throws -> Bool?, expected: Any) throws -> Bool {
        guard let value = try expression() else {
            throw UnexpectedNilError(expected: expected)
        }
        return value
    }
}
