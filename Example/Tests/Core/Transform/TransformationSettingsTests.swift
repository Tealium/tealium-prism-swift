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
}
