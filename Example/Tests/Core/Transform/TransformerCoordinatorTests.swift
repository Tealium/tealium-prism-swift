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
        TransformationSettings(id: "transformation1", transformerId: "transformer1", scopes: [.afterCollectors]),
        TransformationSettings(id: "transformation2", transformerId: "transformer2", scopes: [.allDispatchers]),
        TransformationSettings(id: "transformation3", transformerId: "transformer3", scopes: [.dispatcher(id: "someDispatcher")]),
        TransformationSettings(id: "transformation4", transformerId: "transformer1", scopes: [.allDispatchers]),
        TransformationSettings(id: "transformation5", transformerId: "transformer2", scopes: [.dispatcher(id: "someOtherDispatcher")]),
        TransformationSettings(id: "transformation6", transformerId: "transformer3", scopes: [.afterCollectors]),
        TransformationSettings(id: "transformation7", transformerId: "transformer1", scopes: [.dispatcher(id: "someDispatcher"), .dispatcher(id: "someOtherDispatcher")]),
        TransformationSettings(id: "transformation8",
                               transformerId: "transformer1",
                               scopes: [.allDispatchers],
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
        let transformations = coordinator.getTransformations(for: testEvent, .afterCollectors)
        XCTAssertEqual(transformations.map { $0.id }, ["transformation1", "transformation6"])
    }

    func test_getTransformationsForScope_with_dispatch_filters_by_conditions() {
        let transformations = coordinator.getTransformations(for: testEvent, .dispatcher(id: "someDispatcher"))
        XCTAssertEqual(transformations.map { $0.id }, ["transformation2", "transformation3", "transformation4", "transformation7", "transformation8"])

        let nonMatchingDispatch = Dispatch(name: "other_event")
        let filteredTransformations = coordinator.getTransformations(for: nonMatchingDispatch, .dispatcher(id: "someDispatcher"))
        XCTAssertEqual(filteredTransformations.map { $0.id }, ["transformation2", "transformation3", "transformation4", "transformation7"])
    }

    func test_getTransformationsForScope_dispatcher_returns_allDispatchers_and_dispatcherSpecific_transformations() {
        let transformations = coordinator.getTransformations(for: testEvent, .dispatcher(id: "someDispatcher"))
        XCTAssertEqual(transformations.map { $0.id }, ["transformation2", "transformation3", "transformation4", "transformation7", "transformation8"])
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

    func test_tranformDispatches_forDispatcher_applies_all_related_transformations_in_transformation_order() {
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

    private func transformationCalled(transformation: TransformationSettings) {
        if transformation.id == "transformation\(expectedTransformations[transformationsCount])" {
            allTransformationsAreApplied.fulfill()
            transformationsCount += 1
        } else {
            XCTFail("Unexpected \(transformation) called at count \(transformationsCount)")
        }
    }

    func test_registerTransformation_does_not_add_transformation_and_logs_error_when_condition_throws() {
        let errorLogged = expectation(description: "ConditionEvaluationError logged")
        logger = MockLogger()
        logger?.handler.onLogged.subscribeOnce({ logEvent in
            XCTAssertEqual(logEvent.category, LogCategory.transformations)
            XCTAssertEqual(logEvent.level, .warn)
            errorLogged.fulfill()
        })
        let newTransformation = TransformationSettings(id: "new",
                                                       transformerId: "new",
                                                       scopes: [.allDispatchers],
                                                       conditions: .just(Condition.equals(ignoreCase: false,
                                                                                          variable: "missing",
                                                                                          target: "test")))
        XCTAssertFalse(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.registerTransformation(newTransformation)
        XCTAssertFalse(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        waitForDefaultTimeout()
    }

    func test_registerTransformation_Adds_Transformation_When_Not_Already_Registered() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scopes: [.allDispatchers])
        XCTAssertFalse(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.registerTransformation(newTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
    }

    func test_registerTransformation_Does_Not_Add_Transformation_When_Another_Already_Registered_With_Same_Ids() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scopes: [.allDispatchers])
        let differentTransformation = TransformationSettings(id: "new", transformerId: "new", scopes: [.allDispatchers], configuration: ["some": "value"])
        coordinator.registerTransformation(newTransformation)
        coordinator.registerTransformation(differentTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) && $0.configuration.keys.isEmpty }))
        XCTAssertFalse(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) && $0.configuration == ["some": "value"] }))
    }

    func test_unregisterTransformation_Removes_Transformation_When_Already_Registered() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scopes: [.allDispatchers])
        coordinator.registerTransformation(newTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.unregisterTransformation(newTransformation)
        XCTAssertFalse(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
    }

    func test_unregisterTransformation_Removes_Transformation_When_Another_Already_Registered_With_Same_Ids() {
        let newTransformation = TransformationSettings(id: "new", transformerId: "new", scopes: [.allDispatchers])
        let duplicated = TransformationSettings(id: "new", transformerId: "new", scopes: [.allDispatchers], configuration: ["something": "different"])
        coordinator.registerTransformation(newTransformation)
        XCTAssertTrue(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
        coordinator.unregisterTransformation(duplicated)
        XCTAssertFalse(coordinator.getTransformations(for: testEvent, .dispatcher(id: "new"))
            .contains(where: { coordinator.transformation($0, matchesIdsOf: newTransformation) }))
    }
}
