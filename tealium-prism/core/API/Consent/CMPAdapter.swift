//
//  CMPAdapter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * The `CMPAdapter` provides a consistent interface with external Consent Management
 * Providers (CMP).
 */
public protocol CMPAdapter {
    /**
     * The unique identifier for this `CMPAdapter`.
     */
    var id: String { get }

    /**
     * An observable of the `ConsentDecision`s from the visitor.
     *
     * Subscriptions to this observable always come from the Tealium background queue.
     * You must emit these decisions from a single thread and return an observable that applies
     * `Observable.subscribeOn` with a serial queue backed by that same thread.
     *
     * For example, if the underlying CMP dispatches its events on the main thread, emit from
     * the main thread and pair it with `TealiumQueue.main`:
     *
     * ```swift
     * // the CMP pushes decisions into `decisionSubject` on the main thread
     * var decisionSubject: StateSubject<ConsentDecision?>(nil)
     * var consentDecision: Observable<ConsentDecision?> {
     *     decisionSubject.asObservable()
     *         .subscribeOn(.main)
     * }
     * ```
     *
     * - Warning: Emitting from a queue other than the one passed to `Observable.subscribeOn`
     * will cause race conditions.
     *
     * See `Observable.subscribeOn` for the full contract.
     */
    var consentDecision: Observable<ConsentDecision?> { get }

    /**
     * Returns all possible purposes from the CMP, if available.
     */
    var allPurposes: Set<String>? { get }
}
