//
//  MockTransformer.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 28/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism
import XCTest

class MockTransformer1: MockTransformer {
    class override var moduleType: String { "transformer1" }
    override init(moduleId: String = MockTransformer1.moduleType,
                  transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
                  delay milliseconds: Int? = nil) {
        super.init(moduleId: moduleId, transformation: transformation, delay: milliseconds)
    }
}
class MockTransformer2: MockTransformer {
    class override var moduleType: String { "transformer2" }
    override init(moduleId: String = MockTransformer2.moduleType,
                  transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
                  delay milliseconds: Int? = nil) {
        super.init(moduleId: moduleId, transformation: transformation, delay: milliseconds)
    }
}
class MockTransformer3: MockTransformer {
    class override var moduleType: String { "transformer3" }
    override init(moduleId: String = MockTransformer3.moduleType,
                  transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
                  delay milliseconds: Int? = nil) {
        super.init(moduleId: moduleId, transformation: transformation, delay: milliseconds)
    }
}

class MockTransformer: Transformer {
    static var allowsMultipleInstances: Bool = true
    let version: String = TealiumConstants.libraryVersion
    class var moduleType: String { "MockTransformer" }
    let id: String
    typealias TransformationBlock = (TransformationSettings, Dispatch, DispatchScope) -> Dispatch?
    var transformation: TransformationBlock
    var delay: Int?
    var queue = TealiumQueue.main
    init(moduleId: String = MockTransformer.moduleType,
         transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
         delay milliseconds: Int? = nil) {
        self.id = moduleId
        self.transformation = transformation
        self.delay = milliseconds
    }

    @discardableResult
    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) -> any Disposable {
        let subscription = Disposables.composite(queue: queue)
        if let delay = delay {
            queue.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                guard !subscription.isDisposed else { return }
                completion(self.transformation(transformation, dispatch, scope))
            }
        } else {
            completion(self.transformation(transformation, dispatch, scope))
        }
        return subscription
    }
}

/**
 * A `Transformer` that holds every `applyTransformation` call as a pending step until the test releases it,
 * to simulate transformations that complete asynchronously.
 *
 * A step's completion captures the coordinator's chain, which in turn holds this transformer, so each
 * completion is released right after it is invoked: the mock does not retain a chain once a step has
 * completed, and no per-test cleanup is needed. A disposed step keeps its completion until it is completed,
 * as the `Transformer` contract allows a disposed transformer to still call it and the caller to ignore it.
 */
class AsyncMockTransformer: Transformer {
    /// A single `applyTransformation` call that has not been completed yet.
    class PendingStep {
        let transformation: TransformationSettings
        let dispatch: Dispatch
        let scope: DispatchScope
        /// Whether `applyTransformation` was called on the transformer's `queue`.
        let appliedOnQueue: Bool
        /// The `Disposable` returned to the coordinator for this step, to check whether it was disposed.
        let disposable: any Disposable = Disposables.subscription { }
        /// Guards `completion`: `complete` and `completeAgain` may run on different threads.
        private let lock = NSLock()
        private var completion: ((Dispatch?) -> Void)?

        fileprivate init(transformation: TransformationSettings,
                         dispatch: Dispatch,
                         scope: DispatchScope,
                         appliedOnQueue: Bool,
                         completion: @escaping (Dispatch?) -> Void) {
            self.transformation = transformation
            self.dispatch = dispatch
            self.scope = scope
            self.appliedOnQueue = appliedOnQueue
            self.completion = completion
        }

        /**
         * Returns the completion, releasing it unless `keeping` is true.
         *
         * - returns: `nil` once the completion was released by a previous call.
         */
        fileprivate func takeCompletion(keeping: Bool) -> ((Dispatch?) -> Void)? {
            lock.lock()
            defer { lock.unlock() }
            let completion = self.completion
            if !keeping {
                self.completion = nil
            }
            return completion
        }
    }

    let version: String = TealiumConstants.libraryVersion
    let id: String
    /// The queue each step's `appliedOnQueue` is checked against.
    let queue: TealiumQueue
    /// The steps that have been started and not completed yet, in call order.
    private(set) var pending: [PendingStep] = []
    /**
     * Every step ever started, including those already completed, in call order.
     *
     * Completed steps no longer hold their completion, so keeping them does not retain the chain.
     */
    private(set) var started: [PendingStep] = []

    init(moduleId: String, queue: TealiumQueue = TealiumQueue.main) {
        self.id = moduleId
        self.queue = queue
    }

    func applyTransformation(_ transformation: TransformationSettings,
                             to dispatch: Dispatch,
                             scope: DispatchScope,
                             completion: @escaping (Dispatch?) -> Void) -> any Disposable {
        let step = PendingStep(transformation: transformation,
                               dispatch: dispatch,
                               scope: scope,
                               appliedOnQueue: queue.isOnQueue(),
                               completion: completion)
        pending.append(step)
        started.append(step)
        return step.disposable
    }

    /**
     * Removes `step` from the pending steps and completes it with `result`.
     *
     * The completion is then released, so the step no longer retains the chain. Pass `keepingCompletion: true`
     * only when the test calls `completeAgain` on the same step afterwards. A disposed step is still completed,
     * to prove the coordinator ignores it; a step completed before is only removed from `pending`.
     */
    func complete(_ step: PendingStep, with result: Dispatch?, keepingCompletion: Bool = false) {
        pending.removeAll { $0 === step }
        step.takeCompletion(keeping: keepingCompletion)?(result)
    }

    /**
     * Invokes `step`'s completion a second time with `result`, without touching `pending`, then releases it.
     *
     * This deliberately violates the `Transformer` contract (exactly one completion per step), to test
     * that the coordinator ignores the duplicate. Call it only on a step already passed to
     * `complete(_:with:keepingCompletion:)` with `keepingCompletion: true`; it fails the test otherwise.
     */
    func completeAgain(_ step: PendingStep, with result: Dispatch?) {
        guard let completion = step.takeCompletion(keeping: false) else {
            return XCTFail("The step's completion was already released; complete it with keepingCompletion: true first")
        }
        completion(result)
    }

    /// Completes every currently pending step with its own untransformed dispatch and releases their completions.
    func completeAll() {
        for step in pending {
            complete(step, with: step.dispatch)
        }
    }
}
