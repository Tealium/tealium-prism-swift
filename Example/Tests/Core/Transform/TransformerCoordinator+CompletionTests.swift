//
//  TransformerCoordinator+CompletionTests.swift
//  tealium-prism_Tests
//
//  Created by Karen Tamayo on 04/11/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

// MARK: A transformer that completes a step more than once (contract violation)
final class TransformerCoordinatorCompletionTests: TransformerCoordinatorTestCase {
    func test_transformDispatch_double_completion_applies_remaining_transformations_once() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let second = TransformationSettings(id: "second", transformerId: Self.asyncTransformerId, scope: .afterCollectors)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, second])
        let firstResult = Dispatch(name: "first_result")
        let secondResult = Dispatch(name: "second_result")
        var results: [Dispatch?] = []

        coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
        guard let firstStep = transformer.pending.first else { return XCTFail("First step not started") }

        transformer.complete(firstStep, with: firstResult, keepingCompletion: true)
        transformer.completeAgain(firstStep, with: firstResult)

        XCTAssertEqual(transformer.started.map { $0.transformation.id }, [Self.asyncTransformation.id, second.id])
        guard let secondStep = transformer.pending.first else { return XCTFail("Second step not started") }
        XCTAssertEqual(secondStep.dispatch.id, firstResult.id)
        XCTAssertTrue(results.isEmpty)

        transformer.complete(secondStep, with: secondResult)

        XCTAssertEqual(transformer.started.count, 2)
        XCTAssertEqual(results.map { $0?.id }, [secondResult.id])
    }

    func test_transformDispatch_double_completion_calls_completion_once() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        var results: [Dispatch?] = []

        coordinator.transform(dispatch: testEvent, for: .afterCollectors) { results.append($0) }
        guard let step = transformer.pending.first else { return XCTFail("Step not started") }

        transformer.complete(step, with: testEvent, keepingCompletion: true)
        transformer.completeAgain(step, with: testEvent)

        XCTAssertEqual(results.map { $0?.id }, [testEvent.id])
    }

    func test_transformDispatches_double_completion_completes_batch_once() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]))
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2")]
        var results: [[Dispatch]] = []
        let completed = expectation(description: "Batch completed")

        coordinator.transform(dispatches: dispatches, for: .afterCollectors) {
            results.append($0)
            completed.fulfill()
        }
        let steps = transformer.pending
        XCTAssertEqual(steps.count, 2)
        guard steps.count == 2 else { return }

        transformer.complete(steps[0], with: steps[0].dispatch, keepingCompletion: true)
        transformer.completeAgain(steps[0], with: steps[0].dispatch)
        XCTAssertEqual(results.count, 0)

        transformer.complete(steps[1], with: steps[1].dispatch)

        waitForLongTimeout()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.map { $0.id }, dispatches.map { $0.id })
    }

    func test_transformDispatch_double_completion_logs_warning() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId)
        let logger = MockLogger()
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]), logger: logger)
        var warnings: [MockLogHandler.LogEvent] = []
        let subscription = logger.handler.onLogged.subscribe { event in
            if event.level == .warn {
                warnings.append(event)
            }
        }
        defer { subscription.dispose() }

        coordinator.transform(dispatch: testEvent, for: .afterCollectors) { _ in }
        guard let step = transformer.pending.first else { return XCTFail("Step not started") }

        transformer.complete(step, with: testEvent, keepingCompletion: true)
        XCTAssertEqual(warnings.count, 0)

        transformer.completeAgain(step, with: testEvent)

        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(warnings.first?.category, LogCategory.transformations)
        XCTAssertTrueOptional(warnings.first?.message.contains(Self.asyncTransformerId) ?? false)
        XCTAssertTrueOptional(warnings.first?.message.contains(Self.asyncTransformation.id) ?? false)
    }
}

// MARK: A transformer that completes off the Tealium queue
extension TransformerCoordinatorCompletionTests {
    func test_transformDispatch_resumes_chain_on_queue_when_transformer_completes_on_main() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId, queue: TealiumQueue.worker)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, Self.secondTransformation],
                                          queue: TealiumQueue.worker)
        let firstResult = Dispatch(name: "first_result")
        let secondResult = Dispatch(name: "second_result")
        var calls: [CompletionCall] = []

        onWorkerQueue {
            coordinator.transform(dispatch: self.testEvent, for: .afterCollectors) { calls.append(CompletionCall($0)) }
        }
        guard let firstStep = transformer.pending.first else { return XCTFail("First step not started") }
        complete(firstStep, of: transformer, with: firstResult, from: DispatchQueue.main)

        XCTAssertEqual(transformer.started.map { $0.transformation.id }, [Self.asyncTransformation.id, Self.secondTransformation.id])
        guard let secondStep = transformer.pending.first else { return XCTFail("Second step not started") }
        XCTAssertTrue(secondStep.appliedOnQueue)
        XCTAssertEqual(secondStep.dispatch.id, firstResult.id)
        XCTAssertEqual(calls.count, 0)

        complete(secondStep, of: transformer, with: secondResult, from: DispatchQueue.main)

        XCTAssertEqual(calls.map { $0.dispatch?.id }, [secondResult.id])
        XCTAssertEqual(calls.map { $0.onQueue }, [true])
    }

    func test_transformDispatch_calls_completion_on_queue_when_single_dispatch_transformer_completes_on_another_thread() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId, queue: TealiumQueue.worker)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]), queue: TealiumQueue.worker)
        var calls: [CompletionCall] = []

        onWorkerQueue {
            coordinator.transform(dispatch: self.testEvent, for: .afterCollectors) { calls.append(CompletionCall($0)) }
        }
        guard let step = transformer.pending.first else { return XCTFail("Step not started") }
        XCTAssertEqual(calls.count, 0)

        complete(step, of: transformer, with: testEvent, from: DispatchQueue.global())

        XCTAssertEqual(calls.map { $0.dispatch?.id }, [testEvent.id])
        XCTAssertEqual(calls.map { $0.onQueue }, [true])
    }

    func test_transformDispatches_calls_batch_completion_on_queue_when_transformers_complete_on_another_thread() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId, queue: TealiumQueue.worker)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, Self.secondTransformation],
                                          queue: TealiumQueue.worker)
        let dispatches = [Dispatch(name: "event1"), Dispatch(name: "event2")]
        var batches: [[Dispatch]] = []
        var batchesOnQueue: [Bool] = []

        onWorkerQueue {
            coordinator.transform(dispatches: dispatches, for: .afterCollectors) {
                batches.append($0)
                batchesOnQueue.append(TealiumQueue.worker.isOnQueue())
            }
        }
        let firstSteps = transformer.pending
        XCTAssertEqual(firstSteps.count, 2)
        for step in firstSteps {
            complete(step, of: transformer, with: step.dispatch, from: DispatchQueue.global())
        }

        let secondSteps = transformer.pending
        XCTAssertEqual(secondSteps.map { $0.transformation.id }, [Self.secondTransformation.id, Self.secondTransformation.id])
        XCTAssertEqual(secondSteps.filter { !$0.appliedOnQueue }.count, 0)
        XCTAssertEqual(batches.count, 0)
        for step in secondSteps {
            complete(step, of: transformer, with: step.dispatch, from: DispatchQueue.global())
        }
        waitForWorkerQueue()

        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.map { $0.id }, dispatches.map { $0.id })
        XCTAssertEqual(batchesOnQueue, [true])
    }

    func test_transformDispatch_runs_next_transformation_inline_when_transformer_completes_synchronously() {
        var appliedSteps = 0
        let transformer = MockTransformer(moduleId: Self.asyncTransformerId) { _, dispatch, _ in
            appliedSteps += 1
            return dispatch
        }
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, Self.secondTransformation],
                                          queue: TealiumQueue.worker)
        var calls: [CompletionCall] = []
        var callsBeforeReturn = 0
        var disposedOnReturn = false

        onWorkerQueue {
            let disposable = coordinator.transform(dispatch: self.testEvent, for: .afterCollectors) { calls.append(CompletionCall($0)) }
            callsBeforeReturn = calls.count
            disposedOnReturn = disposable.isDisposed
        }

        XCTAssertEqual(appliedSteps, 2)
        XCTAssertEqual(callsBeforeReturn, 1)
        XCTAssertTrue(disposedOnReturn)
        XCTAssertEqual(calls.map { $0.dispatch?.id }, [testEvent.id])
        XCTAssertEqual(calls.map { $0.onQueue }, [true])
    }

    func test_transformDispatch_ignores_second_completion_when_transformer_completes_twice_from_different_threads() {
        let transformer = AsyncMockTransformer(moduleId: Self.asyncTransformerId, queue: TealiumQueue.worker)
        let coordinator = makeCoordinator(onTransformers: Observables.just([transformer]),
                                          transformations: [Self.asyncTransformation, Self.secondTransformation],
                                          queue: TealiumQueue.worker)
        let firstResult = Dispatch(name: "first_result")
        var calls: [CompletionCall] = []

        onWorkerQueue {
            coordinator.transform(dispatch: self.testEvent, for: .afterCollectors) { calls.append(CompletionCall($0)) }
        }
        guard let firstStep = transformer.pending.first else { return XCTFail("First step not started") }
        let bothCompleted = expectation(description: "Both completions called")
        bothCompleted.expectedFulfillmentCount = 2
        onWorkerQueue {
            transformer.complete(firstStep, with: firstResult, keepingCompletion: true)
            bothCompleted.fulfill()
        }
        DispatchQueue.global().async {
            transformer.completeAgain(firstStep, with: firstResult)
            bothCompleted.fulfill()
        }
        wait(for: [bothCompleted], timeout: Self.longTimeout)
        waitForWorkerQueue()

        XCTAssertEqual(transformer.started.map { $0.transformation.id }, [Self.asyncTransformation.id, Self.secondTransformation.id])
        guard let secondStep = transformer.pending.first else { return XCTFail("Second step not started") }
        XCTAssertEqual(calls.count, 0)

        complete(secondStep, of: transformer, with: secondStep.dispatch, from: TealiumQueue.worker.dispatchQueue)

        XCTAssertEqual(transformer.started.count, 2)
        XCTAssertEqual(calls.map { $0.dispatch?.id }, [firstResult.id])
    }

    private static let secondTransformation = TransformationSettings(id: "second",
                                                                     transformerId: asyncTransformerId,
                                                                     scope: .afterCollectors)

    /// Runs `work` on `TealiumQueue.worker` and waits for it to return.
    private func onWorkerQueue(_ work: @escaping () -> Void) {
        let done = expectation(description: "Work ran on the worker queue")
        TealiumQueue.worker.dispatchQueue.async {
            work()
            done.fulfill()
        }
        wait(for: [done], timeout: Self.longTimeout)
    }

    /// Waits until `TealiumQueue.worker` has run everything enqueued on it so far.
    private func waitForWorkerQueue() {
        onWorkerQueue { }
    }

    /// Completes `step` from `thread`, then waits until `TealiumQueue.worker` has run everything the completion enqueued.
    private func complete(_ step: AsyncMockTransformer.PendingStep,
                          of transformer: AsyncMockTransformer,
                          with result: Dispatch?,
                          from thread: DispatchQueue) {
        let completed = expectation(description: "Step completed")
        thread.async {
            transformer.complete(step, with: result)
            completed.fulfill()
        }
        wait(for: [completed], timeout: Self.longTimeout)
        waitForWorkerQueue()
    }
}

/// A call to a transformation completion, and whether it ran on `TealiumQueue.worker`.
private struct CompletionCall {
    let dispatch: Dispatch?
    let onQueue: Bool

    init(_ dispatch: Dispatch?) {
        self.dispatch = dispatch
        self.onQueue = TealiumQueue.worker.isOnQueue()
    }
}
