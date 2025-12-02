//
//  TemplateProcessorTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/11/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class TemplateProcessorTests: XCTestCase {
    let processor = TemplateProcessor.self
    let context: DataObject = [
        "key": "value",
        "object": [ "property": "value" ],
        "array": ["a", "b", "c"],
        "int": 123,
        "double": 1.2,
        "bool": true,
        "bigDouble": 100_000_000_000_000_000.0,
        "null_key": NSNull(),
        "arrayWithNull": [NSNull()],
        "objectWithNull": ["key": NSNull()]
    ]

    func test_process_replaces_template_when_simple_variable_exists() {
        let result = processor.process(text: "{{key}}",
                                       context: context)
        XCTAssertEqual(result, "value")
    }

    func test_process_replaces_template_when_nested_path_exists() {
        let result = processor.process(text: "{{object.property}}",
                                       context: context)
        XCTAssertEqual(result, "value")
    }

    func test_process_replaces_template_with_fallback_when_key_missing() {
        let result = processor.process(text: "{{ key_missing || fallback }}",
                                       context: context)
        XCTAssertEqual(result, "fallback")
    }

    func test_process_replaces_template_with_first_fallback_when_multiple_fallbacks_provided() {
        let result = processor.process(text: "{{ key_missing || fallback || other }}",
                                       context: context)
        XCTAssertEqual(result, "fallback")
    }

    func test_process_replaces_template_with_blank_when_missing_key_and_missing_fallback() {
        let result = processor.process(text: "There is a blank [{{key_missing}}]",
                                       context: context)
        XCTAssertEqual(result, "There is a blank []")
    }

    func test_process_replaces_template_with_blank_when_missing_key_and_empty_fallback() {
        let result = processor.process(text: "There is a blank [{{key_missing ||}}]",
                                       context: context)
        XCTAssertEqual(result, "There is a blank []")
    }

    func test_process_replaces_template_with_numbers() {
        let result = processor.process(text: "{{ int }} {{ double }}",
                                       context: context)
        XCTAssertEqual(result, "123 1.2")
    }

    func test_process_replaces_template_with_big_numbers() {
        let result = processor.process(text: "{{ bigDouble }}",
                                       context: context)
        XCTAssertEqual(result, "100000000000000000")
    }

    func test_process_replaces_template_with_bools() {
        let result = processor.process(text: "{{ bool }}",
                                       context: context)
        XCTAssertEqual(result, "true")
    }

    func test_process_replaces_template_with_json_object() {
        let result = processor.process(text: "{{ object }}",
                                       context: context)
        XCTAssertEqual(result, "{\"property\":\"value\"}")
    }

    func test_process_replaces_template_with_json_array() {
        let result = processor.process(text: "{{ array }}",
                                       context: context)
        XCTAssertEqual(result, "[\"a\",\"b\",\"c\"]")
    }

    func test_process_replaces_template_with_fallback_when_null() {
        let result = processor.process(text: "{{ null_key || fallback }}",
                                       context: context)
        XCTAssertEqual(result, "fallback")
    }

    func test_process_replaces_template_with_fallback_when_invalid_path() {
        let result = processor.process(text: "{{ invalid..path || fallback }}",
                                       context: context)
        XCTAssertEqual(result, "fallback")
    }

    func test_process_replaces_template_with_null_array_when_array_has_null() {
        let result = processor.process(text: "{{ arrayWithNull }}",
                                       context: context)
        XCTAssertEqual(result, "[null]")
    }

    func test_process_replaces_template_with_null_objects_when_object_has_null() {
        let result = processor.process(text: "{{ objectWithNull }}",
                                       context: context)
        XCTAssertEqual(result, "{\"key\":null}")
    }

    func test_process_trims_whitespaces_around_template_path() {
        let result = processor.process(text: "{{ object.property     }}",
                                       context: context)
        XCTAssertEqual(result, "value")
    }

    func test_process_trims_whitespaces_around_template_fallback() {
        let result = processor.process(text: "{{ missing_key || some fallback     }}",
                                       context: context)
        XCTAssertEqual(result, "some fallback")
    }

    func test_process_replaces_multiple_templates_with_values_and_fallbacks() {
        let result = processor.process(text: """
This {{ object.property || fallback }} is coming from the payload as well as {{ key_missing || this }}.
""",
                                       context: context)
        XCTAssertEqual(result, """
This value is coming from the payload as well as this.
""")
    }

    func test_process_replaces_multiple_templates_on_multiple_lines() {
        let result = processor.process(text: """
First: {{ object.property }}
Second: {{ missing_key || fallback }}
Third: {{ int }}
""",
                                       context: context)
        XCTAssertEqual(result, """
First: value
Second: fallback
Third: 123
""")
    }

    func test_process_returns_original_text_when_no_templates() {
        let result = processor.process(text: "Some text", context: context)
        XCTAssertEqual(result, "Some text")
    }
}
