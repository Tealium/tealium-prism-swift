//
//  TransformationSettingsTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 29/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TransformationSettingsTests: XCTestCase {
    var testEvent = Dispatch(name: "test_event")
    var conditions: Rule<Condition> = .just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event"))
    lazy var transformation = TransformationSettings(id: "test", transformerId: "test", scope: .allDispatchers, conditions: conditions)
    let complexRule = Rule<Condition>.and([
        .just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event")),
        .just(Condition.contains(ignoreCase: false, variable: "screen_name", string: "home"))
    ])

    func test_transformation_matches_matching_dispatch() {
        XCTAssertTrue(try transformation.matchesDispatch(testEvent))
    }

    func test_transformation_does_not_match_non_matching_dispatch() {
        let nonMatchingDispatch = Dispatch(name: "other_event")
        XCTAssertFalse(try transformation.matchesDispatch(nonMatchingDispatch))
    }

    func test_transformation_matches_complex_matching_condition() {
        conditions = complexRule
        testEvent.enrich(data: ["screen_name": "home_screen"])
        XCTAssertTrue(try transformation.matchesDispatch(testEvent))
    }

    func test_transformation_does_not_match_partially_matching_condition() {
        conditions = complexRule
        testEvent.enrich(data: ["screen_name": "profile"])
        XCTAssertFalse(try transformation.matchesDispatch(testEvent))
    }

    func test_transformation_matches_dispatch_without_conditions() {
        let transformation = TransformationSettings(id: "test",
                                                    transformerId: "test",
                                                    scope: .allDispatchers,
                                                    conditions: nil)

        let dispatch = testEvent
        XCTAssertTrue(try transformation.matchesDispatch(dispatch))
    }

    func test_matchesDispatch_throws_the_error_that_condition_matches_throws_inside() {
        let transformation = TransformationSettings(id: "test",
                                                    transformerId: "test",
                                                    scope: .allDispatchers,
                                                    conditions: .just(
                                                        Condition(variable: "missing", operator: .equals(true), filter: "test")
                                                    ))
        let dispatch = testEvent
        XCTAssertThrowsError(try transformation.matchesDispatch(dispatch)) { error in
            guard let error = error as? ConditionEvaluationError,
                    case .missingDataItem = error.kind else {
                XCTFail("Should be a ConditionEvaluationError.missingDataItem error")
                return
            }
        }
    }

    func test_transformation_scope_fromString_returns_correct_scope() {
        XCTAssertEqual(TransformationScope.fromString("aftercollectors"), .afterCollectors)
        XCTAssertEqual(TransformationScope.fromString("AFTERCOLLECTORS"), .afterCollectors) // Case insensitive
        XCTAssertEqual(TransformationScope.fromString("alldispatchers"), .allDispatchers)
        XCTAssertEqual(TransformationScope.fromString("ALLDISPATCHERS"), .allDispatchers) // Case insensitive
    }

    func test_transformation_scope_fromString_returns_nil_for_unrecognized_string() {
        XCTAssertNil(TransformationScope.fromString("unknown"))
        XCTAssertNil(TransformationScope.fromString("Collect"))
        XCTAssertNil(TransformationScope.fromString(""))
    }

    func test_transformation_matches_dispatchers_scope() {
        let transformation = TransformationSettings(id: "test", transformerId: "test",
                                                    scope: .dispatchers(["specific_dispatcher"]),
                                                    conditions: conditions)
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "specific_dispatcher")))
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }

    func test_transformation_does_not_match_different_dispatcher_scope() {
        let transformation = TransformationSettings(id: "test", transformerId: "test",
                                                    scope: .dispatchers(["specific_dispatcher"]),
                                                    conditions: conditions)
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "other_dispatcher")))
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }

    func test_allDispatchers_transformation_matches_any_dispatcher_scope() {
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "any_dispatcher")))
    }

    func test_allDispatchers_transformation_does_not_match_afterCollectors_scope() {
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }

    func test_dispatchers_scope_matching_is_case_sensitive() {
        let transformation = TransformationSettings(id: "test", transformerId: "test",
                                                    scope: .dispatchers(["Collect"]),
                                                    conditions: nil)
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "Collect")))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "collect")))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "COLLECT")))
    }

    func test_dispatchers_transformation_matches_all_listed_dispatcher_ids() {
        let transformation = TransformationSettings(id: "test", transformerId: "test",
                                                    scope: .dispatchers(["Collect", "Facebook"]),
                                                    conditions: nil)
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "Collect")))
        XCTAssertTrue(transformation.matchesScope(.dispatcher(id: "Facebook")))
        XCTAssertFalse(transformation.matchesScope(.dispatcher(id: "Firebase")))
    }
}
