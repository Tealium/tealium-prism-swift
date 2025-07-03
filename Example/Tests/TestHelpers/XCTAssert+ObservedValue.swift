//
//  XCTAssert+ObservedValue.swift
//  tealium-swift_Tests
//
//  Created by Den Guzov on 27/06/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

public extension XCTestCase {
    func XCTAssertObservedValueEqual<T: Equatable>(
        _ expression: @autoclosure () -> Observable<T>,
        _ expectedValue: T,
        in file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Values should be equal")
        expression().subscribeOnce { value in
            XCTAssertEqual(value, expectedValue, file: file, line: line)
            exp.fulfill()
        }
        waitForDefaultTimeout()
    }
}
