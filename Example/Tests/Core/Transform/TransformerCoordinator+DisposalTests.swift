//
//  TransformerCoordinator+DisposalTests.swift
//  tealium-prism_Tests
//
//  Created by Karen Tamayo on 04/11/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

// MARK: Disposal and asynchronous transformers
final class TransformerCoordinatorDisposalTests: TransformerCoordinatorTestCase {
    func test_transformDispatch_dispose_while_waiting_for_transformers_removes_subscription() {
        let tracked = TrackingSubscriptions(ReplaySubject<[Transformer]>().asObservable())
        let coordinator = makeCoordinator(onTransformers: tracked.observable)

        let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in }
        XCTAssertFalse(disposable.isDisposed)
        disposable.dispose()

        XCTAssertEqual(tracked.subscriptionCount, 1)
        XCTAssertTrue(tracked.allDisposed)
    }

    func test_transformDispatches_dispose_while_waiting_for_transformers_removes_subscriptions() {
        let tracked = TrackingSubscriptions(ReplaySubject<[Transformer]>().asObservable())
        let coordinator = makeCoordinator(onTransformers: tracked.observable)

        coordinator.transform(dispatches: [Dispatch(name: "event1"), Dispatch(name: "event2")],
                              for: .afterCollectors) { _ in }
            .dispose()

        XCTAssertEqual(tracked.subscriptionCount, 2)
        XCTAssertTrue(tracked.allDisposed)
    }

    func test_transformDispatch_dispose_before_transformers_ready_applies_nothing() {
        let onTransformers = ReplaySubject<[Transformer]>()
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: onTransformers.asObservable())
        var completionCalls = 0

        coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in completionCalls += 1 }
            .dispose()
        onTransformers.onNext([transformer])

        XCTAssertTrue(transformer.pending.isEmpty)
        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatches_dispose_before_transformers_ready_applies_nothing() {
        let onTransformers = ReplaySubject<[Transformer]>()
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: onTransformers.asObservable())
        var completionCalls = 0
        let completed = expectation(description: "Completion is not called")
        completed.isInverted = true

        coordinator.transform(dispatches: [testEvent], for: .afterCollectors) { _ in
            completionCalls += 1
            completed.fulfill()
        }.dispose()
        onTransformers.onNext([transformer])

        waitForDefaultTimeout()
        XCTAssertTrue(transformer.pending.isEmpty)
        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatch_dispose_while_running_never_calls_completion() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        var completionCalls = 0

        let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in completionCalls += 1 }
        XCTAssertEqual(transformer.pending.count, 1)
        disposable.dispose()
        transformer.completeAll()

        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatches_dispose_never_calls_completion() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        var completionCalls = 0
        let completed = expectation(description: "Completion is not called")
        completed.isInverted = true

        let disposable = coordinator.transform(dispatches: [Dispatch(name: "event1"), Dispatch(name: "event2")],
                                               for: .afterCollectors) { _ in
            completionCalls += 1
            completed.fulfill()
        }
        XCTAssertEqual(transformer.pending.count, 2)
        disposable.dispose()
        transformer.completeAll()

        waitForDefaultTimeout()
        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatch_returns_disposed_disposable_when_transformers_complete_synchronously() {
        let coordinator = makeCoordinator(onTransformers: Observables.just([MockTransformer(moduleId: Self.asyncTransformerId)]))
        var single: [Dispatch?] = []
        var empty: [[Dispatch]] = []

        let singleDisposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { single.append($0) }
        let emptyDisposable = coordinator.transform(dispatches: [], for: .afterCollectors) { empty.append($0) }

        XCTAssertTrue(singleDisposable.isDisposed)
        XCTAssertTrue(emptyDisposable.isDisposed)
        XCTAssertEqual(single.map { $0?.id }, [testEvent.id])
        XCTAssertEqual(empty.count, 1)
        XCTAssertEqual(empty.first?.count, 0)
    }

    func test_transformDispatch_returns_active_disposable_while_transformation_is_running() {
        weak var weakTransformer: AsyncMockTransformer?
        do {
            let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
            weakTransformer = transformer
            let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
            var results: [Dispatch?] = []

            let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
            XCTAssertFalse(disposable.isDisposed)
            XCTAssertTrue(results.isEmpty)

            transformer.completeAll()

            XCTAssertTrue(disposable.isDisposed)
            XCTAssertEqual(results.map { $0?.id }, [testEvent.id])
        }
        XCTAssertNil(weakTransformer, "A completed step releases its completion, so the chain and its transformers are not retained")
    }

    func test_transformDispatch_releases_chain_after_completion_when_transformer_disposable_retains_completion() {
        weak var weakTransformer: CompletionHoldingTransformer?
        do {
            let transformer = CompletionHoldingTransformer(moduleId: Self.asyncTransformerId)
            weakTransformer = transformer
            let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
            var results: [Dispatch?] = []

            let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
            XCTAssertFalse(disposable.isDisposed)

            transformer.completeAll()

            XCTAssertTrue(disposable.isDisposed)
            XCTAssertEqual(results.map { $0?.id }, [testEvent.id])
        }
        XCTAssertNil(weakTransformer, "A completed step releases the rest of the chain, so a Disposable holding its completion does not retain it")
    }

    func test_transformDispatch_does_not_retain_transformer_that_keeps_its_completion_after_calling_it() {
        weak var weakTransformer: CompletionHoldingTransformer?
        do {
            let transformer = CompletionHoldingTransformer(moduleId: Self.asyncTransformerId, keepsCompletedSteps: true)
            weakTransformer = transformer
            let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
            var results: [Dispatch?] = []

            coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
            transformer.completeAll()

            XCTAssertEqual(results.map { $0?.id }, [testEvent.id])
        }
        XCTAssertNil(weakTransformer, "A step's completion does not capture the transformer, so a transformer keeping it does not retain itself")
    }

    func test_transformDispatches_starts_every_dispatch_before_any_completes() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2"), Dispatch(name: "event3")]
        var results: [[Dispatch]] = []
        let completed = expectation(description: "Batch completed")

        coordinator.transform(dispatches: dispatches, for: .afterCollectors) {
            results.append($0)
            completed.fulfill()
        }

        XCTAssertEqual(transformer.pending.map { $0.dispatch.id }, dispatches.map { $0.id })
        XCTAssertTrue(results.isEmpty)

        transformer.completeAll()

        waitForLongTimeout()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.map { $0.id }, dispatches.map { $0.id })
    }

    func test_transformDispatch_applies_transformations_serially_when_transformer_is_async() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let second = TransformationSettings(id: "second", transformerId: Self.asyncTransformerId, scope: .afterCollectors)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, second])
        let firstResult = Dispatch(name: "first_result")
        let secondResult = Dispatch(name: "second_result")
        var results: [Dispatch?] = []

        coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }

        XCTAssertEqual(transformer.pending.count, 1)
        guard let firstStep = transformer.pending.first else { return }
        XCTAssertEqual(firstStep.transformation.id, Self.asyncTransformation.id)
        XCTAssertEqual(firstStep.dispatch.id, testEvent.id)

        transformer.complete(firstStep, with: firstResult)

        XCTAssertEqual(transformer.pending.count, 1)
        guard let secondStep = transformer.pending.first else { return }
        XCTAssertEqual(secondStep.transformation.id, second.id)
        XCTAssertEqual(secondStep.dispatch.id, firstResult.id)
        XCTAssertTrue(results.isEmpty)

        transformer.complete(secondStep, with: secondResult)

        XCTAssertEqual(results.map { $0?.id }, [secondResult.id])
    }

    func test_transformDispatch_dispose_stops_chain_between_transformations() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let second = TransformationSettings(id: "second", transformerId: Self.asyncTransformerId, scope: .afterCollectors)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, second])
        var completionCalls = 0

        let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in completionCalls += 1 }
        guard let firstStep = transformer.pending.first else { return XCTFail("First step not started") }
        disposable.dispose()
        transformer.complete(firstStep, with: testEvent)

        XCTAssertEqual(transformer.started.map { $0.transformation.id }, [Self.asyncTransformation.id])
        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatch_dispose_disposes_running_transformation() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))

        let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in }
        guard let step = transformer.pending.first else { return XCTFail("Step not started") }
        XCTAssertFalse(step.disposable.isDisposed)
        disposable.dispose()

        XCTAssertTrue(step.disposable.isDisposed)
    }

    func test_transformDispatch_dispose_disposes_running_async_transformation_after_a_synchronous_step() throws {
        var synchronousSteps = 0
        let synchronousTransformer = MockTransformer1 { _, dispatch, _ in
            synchronousSteps += 1
            return dispatch
        }
        let asyncTransformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([synchronousTransformer, asyncTransformer]),
                                          transformations: [Self.synchronousTransformation, Self.asyncTransformation])
        var completionCalls = 0

        let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in completionCalls += 1 }
        XCTAssertEqual(synchronousSteps, 1)
        XCTAssertEqual(asyncTransformer.pending.count, 1)
        let step = try XCTUnwrap(asyncTransformer.pending.first)
        XCTAssertFalse(step.disposable.isDisposed)
        disposable.dispose()

        XCTAssertTrue(step.disposable.isDisposed)
        asyncTransformer.completeAll()
        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatches_dispose_disposes_running_transformation_of_every_dispatch() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2"), Dispatch(name: "event3")]

        let disposable = coordinator.transform(dispatches: dispatches, for: .afterCollectors) { _ in }
        let steps = transformer.pending
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps.filter { $0.disposable.isDisposed }.count, 0)
        disposable.dispose()

        XCTAssertEqual(steps.filter { $0.disposable.isDisposed }.count, 3)
    }

    func test_transformDispatches_dispose_disposes_running_async_transformations_of_every_dispatch_after_a_synchronous_step() {
        let asyncTransformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([MockTransformer1(), asyncTransformer]),
                                          transformations: [Self.synchronousTransformation, Self.asyncTransformation])
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2")]
        var completionCalls = 0
        let completed = expectation(description: "Completion is not called")
        completed.isInverted = true

        let disposable = coordinator.transform(dispatches: dispatches, for: .afterCollectors) { _ in
            completionCalls += 1
            completed.fulfill()
        }
        let steps = asyncTransformer.pending
        XCTAssertEqual(steps.map { $0.dispatch.id }, dispatches.map { $0.id })
        XCTAssertEqual(steps.filter { $0.disposable.isDisposed }.count, 0)
        disposable.dispose()

        XCTAssertEqual(steps.filter { $0.disposable.isDisposed }.count, 2)
        asyncTransformer.completeAll()
        waitForDefaultTimeout()
        XCTAssertEqual(completionCalls, 0)
    }

    func test_transformDispatch_completion_disposes_completed_transformation_and_later_dispose_is_harmless() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        var results: [Dispatch?] = []

        let disposable = coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
        guard let step = transformer.pending.first else { return XCTFail("Step not started") }
        transformer.complete(step, with: testEvent)
        XCTAssertTrue(disposable.isDisposed)
        XCTAssertTrue(step.disposable.isDisposed, "A completed chain disposes what it linked, like an Rx operator on completion")
        disposable.dispose()

        XCTAssertEqual(transformer.started.count, 1)
        XCTAssertEqual(results.map { $0?.id }, [testEvent.id])
    }

    func test_transformDispatches_completion_disposes_completed_transformations_and_later_dispose_is_harmless() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2")]
        var results: [[Dispatch]] = []
        let completed = expectation(description: "Batch completed")

        let disposable = coordinator.transform(dispatches: dispatches, for: .afterCollectors) {
            results.append($0)
            completed.fulfill()
        }
        let steps = transformer.pending
        transformer.completeAll()
        waitForLongTimeout()
        XCTAssertEqual(steps.filter { $0.disposable.isDisposed }.count, 2)
        disposable.dispose()

        XCTAssertEqual(transformer.started.count, 2)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.map { $0.id }, dispatches.map { $0.id })
    }

    /// Implemented by a synchronous `MockTransformer1`; ordered before `asyncTransformation` (default order `Int.max`).
    private static let synchronousTransformation = TransformationSettings(id: "synchronous",
                                                                          transformerId: MockTransformer1.moduleType,
                                                                          scope: .afterCollectors,
                                                                          order: 1)
}

// MARK: Dropping the last external reference to the coordinator while a transformation is pending
extension TransformerCoordinatorDisposalTests {
    func test_transformDispatch_completes_chain_and_releases_coordinator_when_reference_is_dropped_mid_chain() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let second = TransformationSettings(id: "second", transformerId: Self.asyncTransformerId, scope: .afterCollectors)
        var coordinator: TransformerCoordinator? = makeCoordinator(onTransformers: Observables.just([transformer]),
                                                                   transformations: [Self.asyncTransformation, second])
#if compiler(>=6.2.3)
        weak let weakCoordinator = coordinator
#else
        weak var weakCoordinator = coordinator
#endif
        let secondResult = Dispatch(name: "second_result")
        var results: [Dispatch?] = []

        _ = coordinator?.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
        guard let firstStep = transformer.pending.first else { return XCTFail("First step not started") }
        coordinator = nil

        transformer.complete(firstStep, with: testEvent)
        guard let secondStep = transformer.pending.first else { return XCTFail("Second step not started") }
        transformer.complete(secondStep, with: secondResult)

        XCTAssertEqual(transformer.started.map { $0.transformation.id }, [Self.asyncTransformation.id, second.id])
        XCTAssertEqual(results.map { $0?.id }, [secondResult.id])
        XCTAssertNil(weakCoordinator, "Once the chain completes, nothing retains the coordinator")
    }

    func test_transformDispatches_completes_batch_and_releases_coordinator_when_reference_is_dropped_mid_chain() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        var coordinator: TransformerCoordinator? = makeCoordinator(onTransformers: Observables.just([transformer]))
#if compiler(>=6.2.3)
        weak let weakCoordinator = coordinator
#else
        weak var weakCoordinator = coordinator
#endif
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2")]
        var results: [[Dispatch]] = []
        let completed = expectation(description: "Batch completed")

        _ = coordinator?.transform(dispatches: dispatches, for: .afterCollectors) {
            results.append($0)
            completed.fulfill()
        }
        XCTAssertEqual(transformer.pending.count, 2)
        coordinator = nil

        transformer.completeAll()

        waitForLongTimeout()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.map { $0.id }, dispatches.map { $0.id })
        XCTAssertNil(weakCoordinator, "Once the batch completes, nothing retains the coordinator")
    }

    func test_transformDispatch_applies_transformations_when_reference_is_dropped_before_transformers_are_ready() {
        let onTransformers = ReplaySubject<[Transformer]>()
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        var coordinator: TransformerCoordinator? = makeCoordinator(onTransformers: onTransformers.asObservable())
#if compiler(>=6.2.3)
        weak let weakCoordinator = coordinator
#else
        weak var weakCoordinator = coordinator
#endif
        var results: [Dispatch?] = []

        _ = coordinator?.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
        coordinator = nil

        onTransformers.onNext([transformer])
        XCTAssertEqual(transformer.started.map { $0.transformation.id }, [Self.asyncTransformation.id])
        XCTAssertTrue(results.isEmpty)
        transformer.completeAll()

        XCTAssertEqual(results.map { $0?.id }, [testEvent.id])
        XCTAssertNil(weakCoordinator, "Once the chain completes, nothing retains the coordinator")
    }
}

/// Wraps `source` so that each subscription to `observable` is recorded, to check whether it was later disposed.
private final class TrackingSubscriptions<Element> {
    private(set) var subscriptions: [any Disposable] = []
    private(set) lazy var observable: Observable<Element> = Observables.create { [unowned self] observer in
        let subscription = self.source.subscribe(observer)
        self.subscriptions.append(subscription)
        return subscription
    }
    private let source: Observable<Element>

    var subscriptionCount: Int { subscriptions.count }
    var allDisposed: Bool { subscriptions.allSatisfy { $0.isDisposed } }

    init(_ source: Observable<Element>) {
        self.source = source
    }
}

/// A step's `Disposable` that keeps its completion, like a cancellable task holding its completion handler.
private final class CompletionHoldingDisposable: Disposable {
    let dispatch: Dispatch
    let completion: (Dispatch?) -> Void
    private(set) var isDisposed = false

    init(dispatch: Dispatch, completion: @escaping (Dispatch?) -> Void) {
        self.dispatch = dispatch
        self.completion = completion
    }

    func dispose() {
        isDisposed = true
    }
}

/**
 * A `Transformer` that returns, for each step, a `Disposable` holding the step's completion.
 *
 * Unlike `AsyncMockTransformer`, a completed step's completion is never released: it lives as long as
 * the `Disposable` returned for it. The transformer itself stops holding a step once it completes it,
 * unless `keepsCompletedSteps` is true.
 */
private final class CompletionHoldingTransformer: Transformer {
    let version: String = TealiumConstants.libraryVersion
    let id: String
    private let keepsCompletedSteps: Bool
    private var pending: [CompletionHoldingDisposable] = []
    /// The steps completed so far, kept only when `keepsCompletedSteps` is true.
    private var completed: [CompletionHoldingDisposable] = []

    init(moduleId: String, keepsCompletedSteps: Bool = false) {
        self.id = moduleId
        self.keepsCompletedSteps = keepsCompletedSteps
    }

    func applyTransformation(_ transformation: TransformationSettings,
                             to dispatch: Dispatch,
                             scope: DispatchScope,
                             completion: @escaping (Dispatch?) -> Void) -> any Disposable {
        let step = CompletionHoldingDisposable(dispatch: dispatch, completion: completion)
        pending.append(step)
        return step
    }

    /// Completes every pending step with its own untransformed dispatch, and stops holding them unless `keepsCompletedSteps` is true.
    func completeAll() {
        let steps = pending
        pending.removeAll()
        if keepsCompletedSteps {
            completed.append(contentsOf: steps)
        }
        steps.forEach { $0.completion($0.dispatch) }
    }
}
