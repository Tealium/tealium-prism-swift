//
//  LazyConstantTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 02/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LazyConstantTests: XCTestCase {

    // LazyConstant is a class, so copies of the wrapping struct share the same instance.
    // This means resolving the value in one copy resolves it for all copies.
    struct Container {
        @LazyConstant var name: String
        init(constructor: @escaping () -> String) {
            self._name = LazyConstant(wrappedValue: constructor())
        }
    }

    // MARK: - init(resolved:)

    func test_init_resolved_returns_value_immediately() {
        let lazy = LazyConstant<String>(resolved: "hello")
        XCTAssertEqual(lazy.wrappedValue, "hello")
    }

    func test_init_resolved_with_nil_value_returns_nil() {
        let lazy = LazyConstant<String?>(resolved: nil)
        XCTAssertNil(lazy.wrappedValue)
    }

    // MARK: - init(wrappedValue:) / init(_:) — lazy evaluation

    func test_init_lazy_does_not_evaluate_constructor_before_first_access() {
        var callCount = 0
        _ = LazyConstant<String>(wrappedValue: {
            callCount += 1
            return "value"
        }())
        XCTAssertEqual(callCount, 0)
    }

    func test_init_lazy_evaluates_constructor_on_first_access() {
        var callCount = 0
        let lazy = LazyConstant<String>(wrappedValue: {
            callCount += 1
            return "value"
        }())
        _ = lazy.wrappedValue
        XCTAssertEqual(callCount, 1)
    }

    func test_init_lazy_evaluates_constructor_only_once() {
        var callCount = 0
        let lazy = LazyConstant<String>(wrappedValue: {
            callCount += 1
            return "value"
        }())
        for _ in 0..<10 {
            _ = lazy.wrappedValue
        }
        XCTAssertEqual(callCount, 1)
    }

    func test_init_lazy_returns_correct_value() {
        let lazy = LazyConstant<Int>(wrappedValue: 42)
        XCTAssertEqual(lazy.wrappedValue, 42)
    }

    func test_init_lazy_with_nil_value_resolves_correctly() {
        var callCount = 0
        let lazy = LazyConstant<String?>(wrappedValue: {
            callCount += 1
            return nil
        }())
        XCTAssertNil(lazy.wrappedValue)
        XCTAssertEqual(callCount, 1)
    }

    func test_init_lazy_with_nil_value_does_not_call_constructor_again_after_resolving_to_nil() {
        var callCount = 0
        let lazy = LazyConstant<String?>(wrappedValue: {
            callCount += 1
            return nil
        }())
        _ = lazy.wrappedValue
        _ = lazy.wrappedValue
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Property wrapper used inside a struct

    func test_property_wrapper_inside_struct_lazy_evaluation() {
        var callCount = 0
        let container = Container {
            callCount += 1
            return "test"
        }
        XCTAssertEqual(callCount, 0)
        _ = container.name
        XCTAssertEqual(callCount, 1)
        _ = container.name
        XCTAssertEqual(callCount, 1)
    }

    func test_property_wrapper_copied_struct_shares_resolved_instance() {
        var callCount = 0
        let container1 = Container {
            callCount += 1
            return "test"
        }
        let container2 = container1
        _ = container1.name
        XCTAssertEqual(callCount, 1)
        _ = container2.name
        XCTAssertEqual(callCount, 1, "Constructor should not be called again on a copy since LazyConstant is a shared reference")
    }
}
