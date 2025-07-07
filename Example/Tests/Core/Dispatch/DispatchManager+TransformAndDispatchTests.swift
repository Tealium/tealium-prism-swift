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
        _sdkSettings.add(modules: [MockDispatcher2.id: ModuleSettings(rules: .just("ruleId"))],
                         loadRules: ["ruleId": LoadRule(id: "ruleId", conditions: .just(condition))])
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
        _sdkSettings.add(modules: [MockDispatcher1.id: ModuleSettings(rules: .just("ruleId"))],
                         loadRules: ["ruleId": LoadRule(id: "ruleId", conditions: .just(condition))])
        let dispatches = [
            Dispatch(name: "Event")
        ]
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = dispatchManager
        wait(for: [transformationIsPerformed, conditionIsChecked],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }

    func test_events_dropped_by_consent_are_removed_from_the_queue() {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        let eventDispatched = expectation(description: "Events should not be dispatched")
        eventDispatched.isInverted = true
        consentManager = MockConsentManager()
        let consentConfiguration = ConsentConfiguration(tealiumPurposeId: "",
                                                        refireDispatchersIds: [],
                                                        purposes: [:])
        consentManager?._onConfigurationSelected.publish(consentConfiguration)
        disableModule(module: module1)
        let dispatches = [
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_be_dropped")
        ]
        module2?.onDispatch.subscribeOnce { _ in
            eventDispatched.fulfill()
        }
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            XCTAssertEqual(dispatches.map { $0.id }, deletedUUIDs)
            eventsAreDeleted.fulfill()
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_events_accepted_by_consent_are_dispatched_removed_from_the_queue() {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        let eventDispatched = expectation(description: "Events should be dispatched")
        consentManager = MockConsentManager()
        consentManager?._onConfigurationSelected.publish(ConsentConfiguration(tealiumPurposeId: "",
                                                                              refireDispatchersIds: [],
                                                                              purposes: ["purpose1": ConsentPurpose(purposeId: "purpose1", dispatcherIds: [MockDispatcher2.id])]))
        disableModule(module: module1)
        let dispatches = [
            Dispatch(name: "event_to_be_sent", data: [ConsentConstants.allPurposesKey: ["purpose1"]]),
            Dispatch(name: "event_to_be_sent", data: [ConsentConstants.allPurposesKey: ["purpose1"]]),
            Dispatch(name: "event_to_be_sent", data: [ConsentConstants.allPurposesKey: ["purpose1"]])
        ]
        module2?.onDispatch.subscribeOnce { _ in
            eventDispatched.fulfill()
        }
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            XCTAssertEqual(dispatches.map { $0.id }, deletedUUIDs)
            eventsAreDeleted.fulfill()
        }
        _ = dispatchManager
        wait(for: [eventDispatched, eventsAreDeleted], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_events_are_not_dequeued_if_consent_enabled_but_configuration_not_present() {
        let eventsAreDeleted = expectation(description: "Events should not be deleted")
        eventsAreDeleted.isInverted = true
        let eventDispatched = expectation(description: "Events should not be dispatched")
        eventDispatched.isInverted = true
        let eventsNotDequeued = expectation(description: "Events are not dequeued")
        consentManager = MockConsentManager()
        disableModule(module: module1)
        let dispatches = [
            Dispatch(name: "event_not_dequeued"),
            Dispatch(name: "event_not_dequeued"),
            Dispatch(name: "event_not_dequeued")
        ]
        module2?.onDispatch.subscribeOnce { _ in
            eventDispatched.fulfill()
        }
        queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onInflightDispatchesCount(for: MockDispatcher2.id).subscribe { count in
            XCTAssertEqual(count, 0)
            eventsNotDequeued.fulfill()
        }
        _ = queueManager.onDeleteRequest.subscribe { _, _ in
            eventsAreDeleted.fulfill()
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }
}
