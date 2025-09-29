//
//  Sha256Tests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 14/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class Sha256Tests: XCTestCase {
    let aString = "Some string"
    func test_string_to_hash() {
        let hashed = aString.sha256()
        XCTAssertEqual(hashed, "2beaf0548e770c4c392196e0ec8e7d6d81cc9280ac9c7f3323e4c6abc231e95a")
    }

    func test_same_string_outputs_same_hash() {
        let hashed = aString.sha256()
        let sameHash = "Some string".sha256()
        XCTAssertEqual(hashed, sameHash)
    }
}
