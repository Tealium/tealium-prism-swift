//
//  DispatchManager+TransformAndDispatchTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerTransformAndDispatchTests: DispatchManagerTestCase {

    func test_events_dropped_by_transformations_are_removed_from_the_queue() {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        let transformerDropsAnEvent = expectation(description: "Transformer drops an event")
        transformers.value = [
            MockTransformer1(transformation: { _, dispatch, scope in
                if dispatch.name == "event_to_be_dropped", scope == .dispatcher(MockDispatcher1.id) {
                    transformerDropsAnEvent.fulfill()
                    return nil
                } else {
                    return dispatch
                }
            })
        ]
        disableModule(module: module2)
        let dispatches = [
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_keep"),
            Dispatch(name: "event_to_keep")
        ]
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            if deletedUUIDs.contains(where: { $0 == dispatches.first?.id }) {
                eventsAreDeleted.fulfill()
            }
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_events_not_allowed_by_loadRules_are_removed_from_the_queue() {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        disableModule(module: module1)
        let condition = Condition.endsWith(ignoreCase: false, variable: "tealium_event", suffix: "to_keep")
        sdkSettings.value = SDKSettings(core: CoreSettings(),
                                        modules: [
                                            MockDispatcher2.id: ModuleSettings(rules: .just("ruleId"))],
                                        loadRules: [
                                            "ruleId": LoadRule(id: "ruleId", conditions: .just(condition))
                                        ])
        let dispatches = [
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_keep"),
            Dispatch(name: "event_to_keep")
        ]
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            if deletedUUIDs.contains(where: { $0 == dispatches.first?.id }) {
                eventsAreDeleted.fulfill()
            }
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_loadRules_are_checked_after_transformations() {
        let conditionIsChecked = expectation(description: "Condition is checked")
        let transformationIsPerformed = expectation(description: "Transformation is performed")
        let condition = MockMatchable(result: true)
        condition.onMatchRequest.subscribeOnce { payload in
            XCTAssertTrue(payload.keys.contains("transformed"))
            conditionIsChecked.fulfill()
        }
        transformers.value = [
            MockTransformer1(transformation: { _, dispatch, _ in
                transformationIsPerformed.fulfill()
                var dispatch = dispatch
                dispatch.enrich(data: ["transformed": "transformed"])
                return dispatch
            })
        ]
        disableModule(module: module2)
        sdkSettings.value = SDKSettings(core: CoreSettings(),
                                        modules: [
                                            MockDispatcher1.id: ModuleSettings(rules: .just("ruleId"))],
                                        loadRules: [
                                            "ruleId": LoadRule(id: "ruleId", conditions: .just(condition))
                                        ])
        let dispatches = [
            Dispatch(name: "Event")
        ]
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = dispatchManager
        wait(for: [transformationIsPerformed, conditionIsChecked],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }
}
