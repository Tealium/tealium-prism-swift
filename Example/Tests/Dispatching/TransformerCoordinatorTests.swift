//
//  TransformerCoordinatorTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 27/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TransformerCoordinatorTests: XCTestCase {
    @TealiumMutableState([
        ScopedTransformation(id: "transformation1", transformerId: "transformer1", scope: [.afterCollectors]),
        ScopedTransformation(id: "transformation2", transformerId: "transformer2", scope: [.allDispatchers]),
        ScopedTransformation(id: "transformation3", transformerId: "transformer3", scope: [.dispatcher("someDispatcher")]),
        ScopedTransformation(id: "transformation4", transformerId: "transformer1", scope: [.allDispatchers]),
        ScopedTransformation(id: "transformation5", transformerId: "transformer2", scope: [.dispatcher("someOtherDispatcher")]),
        ScopedTransformation(id: "transformation6", transformerId: "transformer3", scope: [.afterCollectors]),
        ScopedTransformation(id: "transformation7", transformerId: "transformer1", scope: [.dispatcher("someDispatcher"), .dispatcher("someOtherDispatcher")]),
    ])
    var scopedTransformations: TealiumObservableState<[ScopedTransformation]>
    var registeredTransformers: [MockTransformer] = [
        MockTransformer(id: "transformer1"),
        MockTransformer(id: "transformer2"),
        MockTransformer(id: "transformer3")
    ]
    var transformationsCount = 0
    var expectedTransformations: [Int] = []
    lazy var allTransformationsAreApplied = expectation(description: "All transformations are applied")
    lazy var coordinator = TransformerCoordinator(registeredTransformers: registeredTransformers,
                                                  scopedTransformations: scopedTransformations)

    func test_getTransformationsForScope_afterCollectors_returns_all_afterCollectors_scopedTransformations() {
        let transformations = coordinator.getTransformations(for: .afterCollectors)
        XCTAssertEqual(transformations.map { $0.id }, ["transformation1", "transformation6"])
    }

    func test_getTransformationsForScope_dispatcher_returns_allDispatchers_and_dispatcherSpecific_scopedTransformations() {
        let transformations = coordinator.getTransformations(for: .dispatcher("someDispatcher"))
        XCTAssertEqual(transformations.map { $0.id }, ["transformation2", "transformation3", "transformation4", "transformation7"])
    }

    func test_tranformDispatches_forAfterCollectors_applies_all_related_transformations_in_scopedTransformation_order() {
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

        let dispatch = TealiumDispatch(name: "someEvent")
        coordinator.transform(dispatches: [dispatch], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 1)
            transformationsCompleted.fulfill()
        }
        wait(for: [allTransformationsAreApplied, transformationsCompleted],
             timeout: 1.0,
             enforceOrder: true)
    }

    func test_tranformDispatches_forDispatcher_applies_all_related_transformations_in_scopedTransformation_order() {
        expectedTransformations = [2, 3, 4, 7]
        allTransformationsAreApplied.expectedFulfillmentCount = expectedTransformations.count
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher("someDispatcher")
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

        let dispatch = TealiumDispatch(name: "someEvent")
        coordinator.transform(dispatches: [dispatch], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 1)
            transformationsCompleted.fulfill()
        }
        wait(for: [allTransformationsAreApplied, transformationsCompleted],
             timeout: 1.0,
             enforceOrder: true)
    }

    func test_tranformDispatches_stops_after_first_nil() {
        expectedTransformations = [2, 3]
        allTransformationsAreApplied.expectedFulfillmentCount = expectedTransformations.count
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher("someDispatcher")
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

        let dispatch = TealiumDispatch(name: "someEvent")
        coordinator.transform(dispatches: [dispatch], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 0)
            transformationsCompleted.fulfill()
        }
        wait(for: [allTransformationsAreApplied, transformationsCompleted],
             timeout: 1.0,
             enforceOrder: true)
    }

    func test_tranformDispatches_completes_with_transformed_dispatches() {
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher("someThirdDispatcher")
        registeredTransformers[0].transformation = { _, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            return TealiumDispatch(name: (dispatch.name ?? "") + "-New")
        }
        coordinator.transform(dispatches: [
            TealiumDispatch(name: "someEvent1"),
            TealiumDispatch(name: "someEvent2")
        ], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 2)
            XCTAssertEqual(result[0].name, "someEvent1-New")
            XCTAssertEqual(result[1].name, "someEvent2-New")
            transformationsCompleted.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_tranformDispatches_removes_dispatches_that_are_transformed_to_nil() {
        let transformationsCompleted = expectation(description: "All transformations completed")
        let dispatchScope = DispatchScope.dispatcher("someThirdDispatcher")
        registeredTransformers[0].transformation = { _, dispatch, scope in
            XCTAssertEqual(scope, dispatchScope)
            if dispatch.name == "someEvent1" {
                return nil
            }
            return TealiumDispatch(name: (dispatch.name ?? "") + "-New")
        }
        coordinator.transform(dispatches: [
            TealiumDispatch(name: "someEvent1"),
            TealiumDispatch(name: "someEvent2")
        ], for: dispatchScope) { result in
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0].name, "someEvent2-New")
            transformationsCompleted.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    private func transformationCalled(transformation: String) {
        if transformation == "transformation\(expectedTransformations[transformationsCount])" {
            allTransformationsAreApplied.fulfill()
            transformationsCount += 1
        } else {
            XCTFail("Unexpected \(transformation) called at count \(transformationsCount)")
        }
    }
}
