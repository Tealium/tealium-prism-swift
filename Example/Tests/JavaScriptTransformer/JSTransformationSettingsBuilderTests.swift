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
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.javaScriptTransformer)
    }

    func test_setJsCode_stores_code_in_configuration() {
        let code = "payload.key = 'value'"
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .setJsCode(code)
            .build()
        let jsCode: String? = configDataObject(from: settings).get(key: JavaScriptTransformationSettingsBuilder.Keys.code)
        XCTAssertEqual(jsCode, code)
    }

    func test_setJsCode_empty_string_is_stored_in_configuration() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .setJsCode("")
            .build()
        let jsCode: String? = configDataObject(from: settings).get(key: JavaScriptTransformationSettingsBuilder.Keys.code)
        XCTAssertEqual(jsCode, "")
    }

    func test_setJsCode_called_twice_keeps_last_value() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId)
            .setJsCode("first")
            .setJsCode("second")
            .build()
        let jsCode: String? = configDataObject(from: settings).get(key: JavaScriptTransformationSettingsBuilder.Keys.code)
        XCTAssertEqual(jsCode, "second")
    }

    func test_build_without_setJsCode_omits_js_code_key() {
        let settings = JavaScriptTransformationSettingsBuilder(id: transformationId).build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(JavaScriptTransformationSettingsBuilder.Keys.code))
    }

    func test_setJsCode_returns_builder() {
        let builder = JavaScriptTransformationSettingsBuilder(id: transformationId)
        let result = builder.setJsCode("let a = 42")
        XCTAssertTrue(result === builder)
    }

    private func configDataObject(from settings: DataObject) -> DataObject {
        settings.getDataDictionary(key: TransformationSettings.Keys.configuration)?.toDataObject() ?? [:]
    }
}
