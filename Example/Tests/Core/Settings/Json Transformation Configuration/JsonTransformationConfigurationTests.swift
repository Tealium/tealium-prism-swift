//
//  JsonTransformationConfigurationTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class JsonTransformationConfigurationTests: XCTestCase {
    let configuration = JsonTransformationConfiguration(operationsType: .map,
                                                        operations: [
                                                            TransformationOperation<String>(output: VariableAccessor(variable: "key", path: nil),
                                                                                            parameters: "parameter")
                                                        ])
    func test_toDataObject_returns_object_with_value() throws {
        XCTAssertEqual(configuration.toDataObject(), [
            "operations_type": "map",
            "operations": try DataItem(serializing: [[
                "output": [ "variable": "key"],
                "parameters": "parameter"
            ]])
        ])
    }

    func test_toDataInput_returns_object_with_value() {
        XCTAssertEqual(configuration.toDataInput() as? [String: DataInput], [
            "operations_type": "map",
            "operations": [[
                "output": [ "variable": "key"],
                "parameters": "parameter"
            ]]
        ])
    }
}
