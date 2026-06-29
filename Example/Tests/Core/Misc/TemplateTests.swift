//
//  TemplateTests.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class TemplateTests: XCTestCase {
    let context: DataObject = [
        "key": "value",
        "object": [ "property": "value" ],
        "array": ["a", "b", "c"],
        "int": 123,
        "some.property": "bracketed"
    ]

    func test_compiled_template_processes_simple_substitution() {
        let template = TemplateProcessor.compile("{{key}}")
        XCTAssertEqual(template.process(context: context), "value")
    }

    func test_compiled_template_processes_literal_text_between_substitutions() {
        let template = TemplateProcessor.compile("a {{key}} b {{int}} c")
        XCTAssertEqual(template.process(context: context), "a value b 123 c")
    }

    func test_compiled_template_can_be_reused_across_contexts() {
        let template = TemplateProcessor.compile("Hello {{key}}")
        let first = template.process(context: ["key": "world"])
        let second = template.process(context: ["key": "again"])
        XCTAssertEqual(first, "Hello world")
        XCTAssertEqual(second, "Hello again")
    }

    func test_compiled_template_uses_fallback_when_key_missing() {
        let template = TemplateProcessor.compile("{{ missing || fallback }}")
        XCTAssertEqual(template.process(context: context), "fallback")
    }

    func test_compiled_template_uses_only_first_fallback_when_multiple_provided() {
        let template = TemplateProcessor.compile("{{ missing || fallback || other }}")
        XCTAssertEqual(template.process(context: context), "fallback")
    }

    func test_compiled_template_repeats_same_substitution() {
        let template = TemplateProcessor.compile("{{key}} and {{key}}")
        XCTAssertEqual(template.process(context: context), "value and value")
    }

    func test_compiled_template_returns_original_text_when_no_substitutions() {
        let template = TemplateProcessor.compile("just text")
        XCTAssertEqual(template.process(context: context), "just text")
    }

    func test_substitutions_returns_parsed_paths_in_order() {
        let template = TemplateProcessor.compile("{{key}} {{object.property}} {{array[0]}}")
        XCTAssertEqual(template.substitutions, [
            JSONObjectPath["key"],
            JSONObjectPath["object"]["property"],
            JSONObjectPath["array"][0]
        ])
    }

    func test_substitutions_excludes_invalid_paths() {
        let template = TemplateProcessor.compile("{{ invalid..path || fallback }} {{key}}")
        XCTAssertEqual(template.substitutions, [JSONObjectPath["key"]])
    }

    func test_substitutions_root_keys_can_be_derived() {
        let template = TemplateProcessor.compile("{{object.property}} {{key}}")
        XCTAssertEqual(template.substitutions.map(\.root), ["object", "key"])
    }

    func test_substitutions_root_handles_indexed_and_bracketed_keys() {
        let template = TemplateProcessor.compile("{{ some_key[1] }} {{ [\"some-key-with-chars\"] }}")
        XCTAssertEqual(template.substitutions.map(\.root), ["some_key", "some-key-with-chars"])
    }

    func test_compiled_template_resolves_bracketed_quoted_key() {
        let template = TemplateProcessor.compile("{{ object[\"property\"] }}")
        XCTAssertEqual(template.process(context: context), "value")
    }

    func test_compiled_template_resolves_bracketed_key_with_dot() {
        let template = TemplateProcessor.compile("{{ [\"some.property\"] }}")
        XCTAssertEqual(template.process(context: context), "bracketed")
    }
}
