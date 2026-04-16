//
//  TransformerCoordinatorTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 27/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TransformerCoordinatorTests: XCTestCase {
    @StateSubject([
        TransformationSettings(id: "transformation1", transformerId: "transformer1", scope: .afterCollectors),
        TransformationSettings(id: "transformation2", transformerId: "transformer2", scope: .allDispatchers),
        TransformationSettings(id: "transformation3", transformerId: "transformer3", scope: .dispatchers(["someDispatcher"])),
        TransformationSettings(id: "transformation4", transformerId: "transformer1", scope: .allDispatchers),
        TransformationSettings(id: "transformation5", transformerId: "transformer2", scope: .dispatchers(["someOtherDispatcher"])),
        TransformationSettings(id: "transformation6", transformerId: "transformer3", scope: .afterCollectors),
        TransformationSettings(id: "transformation7", transformerId: "transformer1", scope: .dispatchers(["someDispatcher", "someOtherDispatcher"])),
        TransformationSettings(id: "transformation8",
                               transformerId: "transformer1",
                               scope: .allDispatchers,
                               conditions: .just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event")))
    ])
    var transformations: ObservableState<[TransformationSettings]>
    var registeredTransformers: [MockTransformer] = [
        MockTransformer1(),
        MockTransformer2(),
        MockTransformer3()
    ]
    lazy var transformers = StateSubject<[Transformer]>(registeredTransformers)
    lazy var logger: MockLogger? = nil
    var transformationsCount = 0
    var expectedTransformations: [Int] = []
    lazy var allTransformationsAreApplied = expectation(description: "All transformations are applied")
    lazy var coordinator = TransformerCoordinator(transformers: transformers.asObservableState(),
                                                  transformations: transformations,
                                                  queue: TealiumQueue.worker,
                                                  logger: logger)
    let testEvent = Dispatch(name: "test_event")

    func test_getTransformationsForScope_afterCollectors_returns_all_afterCollectors_transformations() {
        let transformations = coordinator.getTransformations(for: .afterCollectors)
        XCTAssertEqual(transformations.map { $0.id }, ["transformation1", "transformation6"])
    }

    func test_transformDispatches_forAfterCollectors_applies_all_related_transformations_in_transformation_order() {
        expectedTransformations = [1, 6]
        allTransformationsAreApplied.expectedFulfillmentCount = expectedTransformations.count
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.afterCollectors
        registeredTransformers[0].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }
        registeredTransformers[1].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }
        registeredTransformers[2].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }

        let dispatch = Dispatch(name: "someEvent")
        coordinator.transform(dispatches: [dispatch], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 1)
            transformationsCompleted.fulfill()
        }
        wait(for: [allTransformationsAreApplied, transformationsCompleted],
             timeout: Self.longTimeout,
             enforceOrder: true)
    }

    func test_transformDispatches_forDispatcher_applies_all_related_transformations_in_transformation_order() {
        expectedTransformations = [2, 3, 4, 7]
        allTransformationsAreApplied.expectedFulfillmentCount = expectedTransformations.count
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher(id: "someDispatcher")
        registeredTransformers[0].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }
        registeredTransformers[1].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }
        registeredTransformers[2].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }

        let dispatch = Dispatch(name: "someEvent")
        coordinator.transform(dispatches: [dispatch], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 1)
            transformationsCompleted.fulfill()
        }
        wait(for: [allTransformationsAreApplied, transformationsCompleted],
             timeout: Self.longTimeout,
             enforceOrder: true)
    }

    func test_transformDispatches_stops_after_first_nil() {
        expectedTransformations = [2, 3]
        allTransformationsAreApplied.expectedFulfillmentCount = expectedTransformations.count
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher(id: "someDispatcher")
        registeredTransformers[0].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }
        registeredTransformers[1].transformation = { transformation, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return dispatch
        }
        registeredTransformers[2].transformation = { transformation, _, scope in
            XCTAssertEqual(scope, dispatchScope)
            self.transformationCalled(transformation: transformation)
            return nil
        }

        let dispatch = Dispatch(name: "someEvent")
        coordinator.transform(dispatches: [dispatch], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 0)
            transformationsCompleted.fulfill()
        }
        wait(for: [allTransformationsAreApplied, transformationsCompleted],
             timeout: Self.longTimeout,
             enforceOrder: true)
    }

    func test_transformDispatches_completes_with_transformed_dispatches() {
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher(id: "someThirdDispatcher")
        registeredTransformers[0].transformation = { _, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            return Dispatch(name: (dispatch.name ?? "") + "-New")
        }
        coordinator.transform(dispatches: [
            Dispatch(name: "someEvent1"),
            Dispatch(name: "someEvent2")
        ], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 2)
            XCTAssertEqual(result[0].name, "someEvent1-New")
            XCTAssertEqual(result[1].name, "someEvent2-New")
            transformationsCompleted.fulfill()
        }
        waitForLongTimeout()
    }

    func test_transformDispatches_removes_dispatches_that_are_transformed_to_nil() {
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher(id: "someThirdDispatcher")
        registeredTransformers[0].transformation = { _, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            if dispatch.name == "someEvent1" {
                return nil
            }
            return Dispatch(name: (dispatch.name ?? "") + "-New")
        }
        coordinator.transform(dispatches: [
            Dispatch(name: "someEvent1"),
            Dispatch(name: "someEvent2")
        ], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0].name, "someEvent2-New")
            transformationsCompleted.fulfill()
        }
        waitForLongTimeout()
    }

    func test_getTransformations_sorts_by_order_with_lower_order_first_and_unspecified_order_last() {
        let highOrder = TransformationSettings(id: "high", transformerId: "t", scope: .afterCollectors, order: 100)
        let lowOrder = TransformationSettings(id: "low", transformerId: "t", scope: .afterCollectors, order: 1)
        coordinator.registerTransformation(highOrder)
        coordinator.registerTransformation(lowOrder)

        let ids = coordinator.getTransformations(for: .afterCollectors).map { $0.id }
        guard let lowIdx = ids.firstIndex(of: "low"),
              let highIdx = ids.firstIndex(of: "high"),
              let nilIdx = ids.firstIndex(of: "transformation1") else {
            XCTFail("Expected transformations not found in result")
            return
        }
        XCTAssertLessThan(lowIdx, highIdx)
        XCTAssertLessThan(highIdx, nilIdx)
    }

    func test_getTransformations_updates_cache_when_settings_change() {
        XCTAssertFalse(coordinator.getTransformations(for: .afterCollectors).isEmpty)
        _transformations.value = [
            TransformationSettings(id: "new1", transformerId: "transformer1", scope: .afterCollectors)
        ]
        XCTAssertEqual(coordinator.getTransformations(for: .afterCollectors).map { $0.id }, ["new1"])
    }

    func test_getTransformations_merges_and_sorts_settings_and_additional_after_settings_change() {
        _transformations.value = [
            TransformationSettings(id: "fromSettings", transformerId: "transformer2", scope: .afterCollectors, order: 2)
        ]
        let additional = TransformationSettings(id: "additional", transformerId: "transformer1", scope: .afterCollectors, order: 1)
        coordinator.registerTransformation(additional)
        XCTAssertEqual(coordinator.getTransformations(for: .afterCollectors).map { $0.id }, ["additional", "fromSettings"])
    }

    func test_transform_evaluates_conditions_after_each_transformation_mutates_dispatch() {
        // transformation1 (transformer1, afterCollectors) runs first and adds "custom_key"
        // conditionalTransformation (transformer3, afterCollectors) has condition custom_key == "custom_value"
        // Without deferred checking it would be skipped (original dispatch lacks custom_key);
        // with deferred checking it runs because transformation1 already mutated the dispatch.
        registeredTransformers[0].transformation = { _, dispatch, _ in
            var mutated = dispatch
            mutated.enrich(data: ["custom_key": "custom_value"])
            return mutated
        }
        let conditionalTransformation = TransformationSettings(
            id: "conditional",
            transformerId: "transformer3",
            scope: .afterCollectors,
            conditions: .just(Condition.equals(ignoreCase: false, variable: "custom_key", target: "custom_value"))
        )
        coordinator.registerTransformation(conditionalTransformation)

        let conditionalApplied = expectation(description: "Conditional transformation applied after mutation")
        registeredTransformers[2].transformation = { transformation, dispatch, _ in
            if transformation.id == "conditional" {
                conditionalApplied.fulfill()
            }
            return dispatch
        }
        let completed = expectation(description: "Transform completed")
        coordinator.transform(dispatch: Dispatch(name: "some_event"), for: .afterCollectors) { _ in
            completed.fulfill()
        }
        wait(for: [conditionalApplied, completed], timeout: Self.longTimeout)
    }

    private func transformationCalled(transformation: TransformationSettings) {
        if transformation.id == "transformation\(expectedTransformations[transformationsCount])" {
            allTransformationsAreApplied.fulfill()
            transformationsCount += 1
        } else {
            XCTFail("Unexpected \(transformation) called at count \(transformationsCount)")
        }
    }

    func test_transform_skips_transformation_and_logs_error_when_condition_throws() {
        let errorLogged = expectation(description: "ConditionEvaluationError logged")
        logger = MockLogger()
        logger?.handler.onLogged.subscribeOnce({ logEvent in
            XCTAssertEqual(logEvent.category, LogCategory.transformations)
            XCTAssertEqual(logEvent.level, .warn)
            errorLogged.fulfill()
        })
        let throwingTransformation = TransformationSettings(id: "throwing",
                                                            transformerId: "transformer1",
                                                            scope: .allDispatchers,
                                                            conditions: .just(Condition(variable: "missing",
                                                                                        operator: .equals(true),
                                                                                        filter: "test")))
        coordinator.registerTransformation(throwingTransformation)

        let calledForThrowingTransformation = expectation(description: "Transformer should not be called for throwing condition evaluation")
        calledForThrowingTransformation.isInverted = true
        registeredTransformers[0].transformation = { transformation, dispatch, _ in
            if transformation.id == "throwing" {
                calledForThrowingTransformation.fulfill()
            }
            return dispatch
        }
        let completed = expectation(description: "Transform completed")
        coordinator.transform(dispatch: testEvent, for: .dispatcher(id: "someDispatcher")) { _ in
            completed.fulfill()
        }
        wait(for: [completed], timeout: Self.longTimeout)
        wait(for: [errorLogged, calledForThrowingTransformation], timeout: Self.defaultTimeout)
    }

    func test_registerTransformation_adds_transformation_when_not_already_registered() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scope: .allDispatchers)
        XCTAssertFalse(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.registerTransformation(newTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
    }

    func test_registerTransformation_does_not_add_transformation_when_another_already_registered_with_same_ids() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scope: .allDispatchers)
        let differentTransformation = TransformationSettings(id: "new", transformerId: "new", scope: .allDispatchers, configuration: ["some": "value"])
        coordinator.registerTransformation(newTransformation)
        coordinator.registerTransformation(differentTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) && $0.configuration.keys.isEmpty }))
        XCTAssertFalse(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) && $0.configuration == ["some": "value"] }))
    }

    func test_unregisterTransformation_removes_transformation_when_already_registered() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scope: .allDispatchers)
        coordinator.registerTransformation(newTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.unregisterTransformation(newTransformation)
        XCTAssertFalse(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
    }

    func test_unregisterTransformation_removes_transformation_when_another_already_registered_with_same_ids() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scope: .allDispatchers)
        let duplicated = TransformationSettings(id: "new", transformerId: "new", scope: .allDispatchers, configuration: ["something": "different"])
        coordinator.registerTransformation(newTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.unregisterTransformation(duplicated)
        XCTAssertFalse(coordinator.getTransformations(for: .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
    }
}
