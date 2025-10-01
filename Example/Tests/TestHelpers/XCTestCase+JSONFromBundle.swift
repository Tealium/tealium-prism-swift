//
//  XCTestCase+JSONFromBundle.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

extension XCTestCase {
    enum JSONError: TealiumErrorEnum {
        case pathNotFoundForResource(String)
        case conversionToStringFailed
    }
    func jsonStringFromBundle(_ path: String) throws -> String {
        let bundle = Bundle(for: type(of: self))
        guard let path = TealiumFileManager.fullJSONPath(from: bundle, relativePath: path) else {
            throw JSONError.pathNotFoundForResource(name)
        }
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        guard let stringData = String(data: jsonData, encoding: .utf8) else {
            throw JSONError.conversionToStringFailed
        }
        return stringData
    }
}
