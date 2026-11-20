//
//  DispatchManager+TransformAndDispatchTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchManagerTransformAndDispatchTests: DispatchManagerTestCase {

    func test_events_dropped_by_transformations_are_removed_from_the_queue() throws {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        let transformerDropsAnEvent = expectation(description: "Transformer drops an event")
        transformers.value = [
            MockTransformer1(transformation: { _, dispatch, scope in
                if dispatch.name == "event_to_be_dropped", scope == .dispatcher(id: MockDispatcher1.moduleType) {
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
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            if deletedUUIDs.contains(where: { $0 == dispatches.first?.id }) {
                eventsAreDeleted.fulfill()
            }
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_all_events_not_allowed_by_loadRules_are_removed_from_the_queue_without_dispatching() throws {
        disableModule(module: module1)
        let condition = Condition.endsWith(ignoreCase: false, variable: "tealium_event", suffix: "to_keep")
        _sdkSettings.add(modules: [MockDispatcher2.moduleType: ModuleSettings(moduleType: MockDispatcher2.moduleType,
                                                                              rules: "ruleId")],
                         loadRules: ["ruleId": LoadRule(id: "ruleId", conditions: .just(condition))])
        let dispatches = [
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_be_dropped")
        ]
        let eventsAreDeleted = expectation(description: "Events are deleted from the queue")
        let eventsAreDispatched = expectation(description: "Dispatcher is not called")
        eventsAreDispatched.isInverted = true
        module2?.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            if dispatches.map({ $0.id }) == deletedUUIDs {
                eventsAreDeleted.fulfill()
            }
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_events_not_allowed_by_loadRules_are_removed_from_the_queue() throws {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        disableModule(module: module1)
        let condition = Condition.endsWith(ignoreCase: false, variable: "tealium_event", suffix: "to_keep")
        _sdkSettings.add(modules: [MockDispatcher2.moduleType: ModuleSettings(moduleType: MockDispatcher2.moduleType,
                                                                              rules: "ruleId")],
                         loadRules: ["ruleId": LoadRule(id: "ruleId", conditions: .just(condition))])
        let dispatches = [
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_keep"),
            Dispatch(name: "event_to_keep")
        ]
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            if deletedUUIDs.contains(where: { $0 == dispatches.first?.id }) {
                eventsAreDeleted.fulfill()
            }
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_loadRules_are_checked_after_transformations() throws {
        let transformationIsPerformed = expectation(description: "Transformation is performed")
        let condition = Condition.isDefined(variable: "transformed")
        transformers.value = [
            MockTransformer1(transformation: { _, dispatch, _ in
                transformationIsPerformed.fulfill()
                var dispatch = dispatch
                dispatch.enrich(data: ["transformed": "transformed"])
                return dispatch
            })
        ]
        disableModule(module: module2)
        _sdkSettings.add(modules: [MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType,
                                                                              rules: "ruleId")],
                         loadRules: ["ruleId": LoadRule(id: "ruleId", conditions: .just(condition))])
        let dispatches = [
            Dispatch(name: "Event")
        ]
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_events_dropped_by_consent_are_removed_from_the_queue() throws {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        let eventDispatched = expectation(description: "Events should not be dispatched")
        eventDispatched.isInverted = true
        consentManager = MockConsentManager()
        let consentConfiguration = ConsentConfiguration(tealiumPurposeId: "",
                                                        refireDispatchersIds: [],
                                                        purposes: [:])
        consentManager?._onConfigurationSelected.onNext(consentConfiguration)
        disableModule(module: module1)
        let dispatches = [
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_be_dropped"),
            Dispatch(name: "event_to_be_dropped")
        ]
        module2?.onDispatch.subscribeOnce { _ in
            eventDispatched.fulfill()
        }
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            XCTAssertEqual(dispatches.map { $0.id }, deletedUUIDs)
            eventsAreDeleted.fulfill()
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_events_accepted_by_consent_are_dispatched_removed_from_the_queue() throws {
        let eventsAreDeleted = expectation(description: "Events are deleted")
        let eventDispatched = expectation(description: "Events should be dispatched")
        consentManager = MockConsentManager()
        consentManager?._onConfigurationSelected.onNext(ConsentConfiguration(tealiumPurposeId: "",
                                                                             refireDispatchersIds: [],
                                                                             purposes: ["purpose1": ConsentPurpose(purposeId: "purpose1", dispatcherIds: [MockDispatcher2.moduleType])]))
        disableModule(module: module1)
        let dispatches = [
            Dispatch(name: "event_to_be_sent", data: [TealiumDataKey.allConsentedPurposes: ["purpose1"]]),
            Dispatch(name: "event_to_be_sent", data: [TealiumDataKey.allConsentedPurposes: ["purpose1"]]),
            Dispatch(name: "event_to_be_sent", data: [TealiumDataKey.allConsentedPurposes: ["purpose1"]])
        ]
        module2?.onDispatch.subscribeOnce { _ in
            eventDispatched.fulfill()
        }
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            XCTAssertEqual(dispatches.map { $0.id }, deletedUUIDs)
            eventsAreDeleted.fulfill()
        }
        _ = dispatchManager
        wait(for: [eventDispatched, eventsAreDeleted], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_mixed_consent_batch_deletes_both_accepted_and_rejected_events() throws {
        let allEventsAreDeleted = expectation(description: "All events are deleted from the queue")
        allEventsAreDeleted.expectedFulfillmentCount = 3
        consentManager = MockConsentManager()
        consentManager?._onConfigurationSelected.onNext(ConsentConfiguration(tealiumPurposeId: "",
                                                                             refireDispatchersIds: [],
                                                                             purposes: ["purpose1": ConsentPurpose(purposeId: "purpose1", dispatcherIds: [MockDispatcher2.moduleType])]))
        disableModule(module: module1)
        let accepted = Dispatch(name: "accepted_event", data: [TealiumDataKey.allConsentedPurposes: ["purpose1"]])
        let rejected1 = Dispatch(name: "rejected_event")
        let rejected2 = Dispatch(name: "rejected_event")
        let dispatches = [accepted, rejected1, rejected2]
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onDeleteRequest.subscribe { deletedUUIDs, _ in
            for id in deletedUUIDs where dispatches.map({ $0.id }).contains(id) {
                allEventsAreDeleted.fulfill()
            }
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    func test_events_are_not_dequeued_if_consent_enabled_but_configuration_not_present() throws {
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
        try queueManager.storeDispatches(dispatches, enqueueingFor: allDispatchers)
        _ = queueManager.onInflightDispatchesCount(for: MockDispatcher2.moduleType)
            .subscribe { count in
                XCTAssertEqual(count, 0)
                eventsNotDequeued.fulfill()
            }
        _ = queueManager.onDeleteRequest.subscribe { _, _ in
            eventsAreDeleted.fulfill()
        }
        _ = dispatchManager
        waitForDefaultTimeout()
    }

    // MARK: - Transformation in progress

    /// Stopping the loop disposes the transformation of a batch already dequeued, through the `Disposable`
    /// that `transformAndDispatch` holds for it.
    func test_stopDispatchLoop_disposes_transformation_in_progress() throws {
        let batch = try startPendingTransformation()

        dispatchManager.stopDispatchLoop()

        XCTAssertTrue(batch.step.disposable.isDisposed)
        XCTAssertTrue(batch.transformer.pending.first === batch.step, "Disposing a step does not complete it")
    }

    /// A transformer that completes after the loop was stopped must not get its batch sent nor deleted.
    func test_stopDispatchLoop_during_transformation_does_not_dispatch() throws {
        let batch = try startPendingTransformation()
        let module1 = try XCTUnwrap(module1)
        var dispatchCalls = 0
        _ = module1.onDispatch.subscribe { _ in dispatchCalls += 1 }
        var deleteRequests = 0
        _ = queueManager.onDeleteRequest.subscribe { _, _ in deleteRequests += 1 }

        dispatchManager.stopDispatchLoop()
        batch.transformer.completeAll()
        drainMainQueue()

        XCTAssertEqual(dispatchCalls, 0)
        XCTAssertEqual(deleteRequests, 0)
        XCTAssertEqual(queueManager.inflightEvents.value[module1.id],
                       Set([batch.step.dispatch.id]),
                       "The dispatch is still held in the queue")
    }

    /// `transformAndDispatch` sits downstream of the `flatMapLatest` that rebuilds the dequeue loops, so a change to
    /// the dispatcher list leaves a running transformation alone and its batch is still sent.
    func test_dispatcher_list_change_does_not_cancel_transformation_in_progress() throws {
        let batch = try startPendingTransformation()
        let module1 = try XCTUnwrap(module1)
        var sentBatches: [[Dispatch]] = []
        let sent = expectation(description: "module1 receives the batch")
        _ = module1.onDispatch.subscribe { dispatches in
            sentBatches.append(dispatches)
            sent.fulfill()
        }

        enableModule(MockDispatcher2.moduleType)
        XCTAssertEqual(allDispatchers.count, 2, "Precondition: the dispatcher list changed")
        XCTAssertFalse(batch.step.disposable.isDisposed)

        batch.transformer.complete(batch.step, with: batch.step.dispatch)
        wait(for: [sent], timeout: Self.longTimeout)
        drainMainQueue()
        XCTAssertEqual(sentBatches.map { $0.map(\.id) }, [[batch.step.dispatch.id]])
    }

    /// The single-dispatch path: a step completed twice reaches `onTrackResult`, and the queue, only once.
    func test_track_calls_onTrackResult_once_when_transformer_completes_twice() throws {
        let asyncTransformer = AsyncMockTransformer(moduleId: "async")
        registerTransformation(asyncTransformer, scope: .afterCollectors)
        var trackResults = 0
        var storeRequests = 0
        _ = queueManager.onStoreRequest.subscribe { _, _ in storeRequests += 1 }

        dispatchManager.track(Dispatch(name: "someEvent")) { _ in trackResults += 1 }
        XCTAssertEqual(asyncTransformer.pending.count, 1)
        let step = try XCTUnwrap(asyncTransformer.pending.first)
        asyncTransformer.complete(step, with: step.dispatch, keepingCompletion: true)
        asyncTransformer.completeAgain(step, with: step.dispatch)
        drainMainQueue()

        XCTAssertEqual(trackResults, 1)
        XCTAssertEqual(storeRequests, 1)
    }

    // MARK: - Helpers

    private struct PendingBatch {
        let transformer: AsyncMockTransformer
        let step: AsyncMockTransformer.PendingStep
    }

    /// Appends `transformer` to the registered transformers, with a transformation implemented by it and scoped to `scope`.
    private func registerTransformation(_ transformer: Transformer, scope: TransformationScope) {
        transformers.value.append(transformer)
        transformerCoordinator.registerTransformation(TransformationSettings(id: "transformation-\(transformer.id)",
                                                                             transformerId: transformer.id,
                                                                             scope: scope))
    }

    /// Starts the loop with `module1` alone and tracks one dispatch, so that it is dequeued and held by an
    /// `AsyncMockTransformer` scoped to `module1`, then returns that transformer and its single pending step.
    private func startPendingTransformation() throws -> PendingBatch {
        let asyncTransformer = AsyncMockTransformer(moduleId: "async")
        registerTransformation(asyncTransformer, scope: .dispatchers([MockDispatcher1.moduleType]))
        disableModule(module: module2)
        let dequeued = expectation(description: "The dispatch is dequeued for module1")
        queueManager.onInflightDispatchesCount(for: MockDispatcher1.moduleType)
            .filter { $0 > 0 }
            .subscribeOnce { _ in dequeued.fulfill() }

        dispatchManager.track(Dispatch(name: "someEvent"))
        wait(for: [dequeued], timeout: Self.longTimeout)

        XCTAssertEqual(asyncTransformer.pending.count, 1)
        let step = try XCTUnwrap(asyncTransformer.pending.first)
        return PendingBatch(transformer: asyncTransformer, step: step)
    }

}
