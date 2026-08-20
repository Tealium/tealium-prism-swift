//
//  Data+GunzippedJSON.swift
//  tealium-prism_Tests
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism
import XCTest

extension Data {
    func gunzippedJSON(file: StaticString = #filePath, line: UInt = #line) -> [String: Any]? {
        guard let unzipped = try? gunzipped(),
              let json = try? JSONSerialization.jsonObject(with: unzipped) as? [String: Any] else {
            XCTFail("Could not gunzip and deserialize JSON body", file: file, line: line)
            return nil
        }
        return json
    }
}
