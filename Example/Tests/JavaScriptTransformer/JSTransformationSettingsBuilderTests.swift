//
//  JSTransformationSettingsBuilderTests.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class JSTransformationSettingsBuilderTests: XCTestCase {

    let transformationId = "test-transformation"

    func test_build_sets_transformer_id() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.javaScriptTransformer)
    }

    func test_setJsCode_stores_code_in_configuration() {
        let code = "payload.key = 'value'"
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .setJsCode(code)
            .build()
        XCTAssertEqual(settings.configuration.get(key: "js_code"), code)
    }

    func test_setJsCode_empty_string_is_stored_in_configuration() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .setJsCode("")
            .build()
        XCTAssertEqual(settings.configuration.get(key: "js_code"), "")
    }

    func test_setJsCode_called_twice_keeps_last_value() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .setJsCode("first")
            .setJsCode("second")
            .build()
        XCTAssertEqual(settings.configuration.get(key: "js_code"), "second")
    }

    func test_addScope_is_included_in_build() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .build()
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertEqual(settings.scopes.count, 1)
    }

    func test_build_with_no_code_has_nil_js_code_in_configuration() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId).build()
        let code: String? = settings.configuration.get(key: "js_code")
        XCTAssertNil(code)
    }
}
