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
    var scopes = [TransformationScope.allDispatchers]
    var conditions: Rule<Condition> = .just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event"))
    lazy var transformation = TransformationSettings(id: "test", transformerId: "test", scopes: scopes, conditions: conditions)
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
        // Test with no conditions (should always match)
        let transformation = TransformationSettings(id: "test",
                                                    transformerId: "test",
                                                    scopes: [.allDispatchers],
                                                    conditions: nil)

        let dispatch = testEvent
        XCTAssertTrue(try transformation.matchesDispatch(dispatch))
    }

    func test_matchesDispatch_throws_the_error_that_condition_matches_throws_inside() {
        let transformation = TransformationSettings(id: "test",
                                                    transformerId: "test",
                                                    scopes: [.allDispatchers],
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

    func test_transformation_scope_rawValue() {
        // Test the rawValue property for all cases
        XCTAssertEqual(TransformationScope.afterCollectors.rawValue, "aftercollectors")
        XCTAssertEqual(TransformationScope.allDispatchers.rawValue, "alldispatchers")
        XCTAssertEqual(TransformationScope.dispatcher("test_dispatcher").rawValue, "test_dispatcher")
    }

    func test_transformation_scope_init_from_rawValue() {
        // Test initialization from rawValue for all cases
        XCTAssertEqual(TransformationScope(rawValue: "aftercollectors"), .afterCollectors)
        XCTAssertEqual(TransformationScope(rawValue: "AFTERCOLLECTORS"), .afterCollectors) // Case insensitive
        XCTAssertEqual(TransformationScope(rawValue: "alldispatchers"), .allDispatchers)
        XCTAssertEqual(TransformationScope(rawValue: "ALLDISPATCHERS"), .allDispatchers) // Case insensitive
        XCTAssertEqual(TransformationScope(rawValue: "test_dispatcher"), .dispatcher("test_dispatcher"))
    }

    func test_transformation_matches_equal_scopes() {
        scopes = [.afterCollectors, .dispatcher("specific_dispatcher")]
        XCTAssertTrue(transformation.matchesScope(.afterCollectors))
        XCTAssertTrue(transformation.matchesScope(.dispatcher("specific_dispatcher")))
    }

    func test_transformation_does_not_match_different_scopes() {
        scopes = [.dispatcher("specific_dispatcher")]
        XCTAssertFalse(transformation.matchesScope(.dispatcher("other_dispatcher")))
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }

    func test_allDispatcher_transformation_matches_any_dispatcher_scope() {
        XCTAssertTrue(transformation.matchesScope(.dispatcher("any_dispatcher")))
    }

    func test_allDispatcher_transformation_does_not_match_afterCollectors_scope() {
        XCTAssertFalse(transformation.matchesScope(.afterCollectors))
    }
}
