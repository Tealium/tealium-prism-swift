//
//  Single.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A `Subscribable` implementation whereby only a single result is expected to be emitted to the subscriber.
public class Single<Element>: Subscribable {
    private let subscribable: any Subscribable<Element>
    init(observable: Observable<Element>, queue: TealiumQueue) {
        self.subscribable = observable
            .first()
            .subscribeOn(queue)
    }

    @discardableResult
    public func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        subscribable.subscribe(observer)
    }
}

extension Result: ErrorExtractor {
    public func getError() -> Failure? {
        guard case let .failure(error) = self else {
            return nil
        }
        return error
    }
}

extension Result: ValueExtractor {
    public func getValue() -> Success? {
        try? get()
    }
}

/// An object from which you can extract an optional error.
public protocol ErrorExtractor<ErrorType> {
    /// The type of error that can be extracted.
    associatedtype ErrorType: Error
    /// - Returns: An error, if it's present in the object, or nil.
    func getError() -> ErrorType?
}

/// An object from which you can extract an optional value.
public protocol ValueExtractor<ValueType> {
    /// The type of value that can be extracted.
    associatedtype ValueType
    /// - Returns: The value, if it's present in the object, or nil.
    func getValue() -> ValueType?
}

/**
 *  A `Single` that completes with a `Result<T, Error>`.
 *
 * With a `SingleResult` you can `subscribe` as any other type of `Single`,
 * but you can also subscribe only for `onSuccess` or `onFailure` to receive the event
 * only in case the event is respectively either a success or a failure.
 *
 * So in case you want to handle both success and failure:
 * ```swift
 * single.subscribe { result in
 *      switch result {
 *       case let .success(output):
 *          // Handle success
 *          break
 *       case let .failure(error):
 *          // Handle failure
 *          break
 * }
 * ```
 *
 * In case you want to handle only successes:
 * ```swift
 * single.onSuccess { output in
 *   // Handle success
 * }
 * ```
 *
 * In case you want to handle only failures:
 * ```swift
 * single.onFailure { error in
 *   // Handle failure
 * }
 */
public typealias SingleResult<T, E: Error> = Single<Result<T, E>>

public extension Single {
    /**
     * Subscribe an handler to this `Single` which will be called at most once if the `Single` is successful.
     *
     * - Parameters:
     *  - handler: The callback that will be called if the `Single` is successful with the value extracted from the result.
     *
     * - Returns: A `Disposable` that can be disposed if the handler is no longer necessary.
     */
    @discardableResult
    func onSuccess<Value>(handler: @escaping (_ output: Value) -> Void) -> any Disposable where Element: ValueExtractor<Value> {
        subscribe { result in
            if let value = result.getValue() {
                handler(value)
            }
        }
    }

    /**
     * Subscribe an handler to this `Single` which will be called at most once if the `Single` is unsuccessful.
     *
     * - Parameters:
     *  - handler: The callback that will be called if the `Single` is unsuccessful with the error extracted from the result.
     *
     * - Returns: A `Disposable` that can be disposed if the handler is no longer necessary.
     */
    @discardableResult
    func onFailure<ErrorType>(handler: @escaping (_ error: ErrorType) -> Void) -> any Disposable where Element: ErrorExtractor<ErrorType> {
        subscribe { result in
            if let error = result.getError() {
                handler(error)
            }
        }
    }
}

public extension Single {
    /// Transforms this Single into an async function that can be awaited on.
    ///
/// - Returns: The generic `Value` emitted by the underlying `Single`.
/// - Throws: The generic `Failure` emitted by the underlying `Single`, or a `CancellationError` if the Single completes before emitting the `Result`.
    func toAsync<Value, Failure: Error>() async throws -> Value where Element == Result<Value, Failure> {
        // `withCheckedThrowingContinuation` throws a generic Error, so we can't force this to be of type Failure.
        // Nonetheless it's still useful to support multiple Failure types or we can't call this on SingleResult with typed errors.
        try await withCheckedThrowingContinuation { continuation in
            let continuation = SelfDestructingCompletion { (result: Result<Value, Error>) in
                continuation.resume(with: result)
            }
            _ = self.subscribe { result in
                continuation.complete(result: result.mapError { $0 })
            } onComplete: {
                continuation.complete(result: .failure(CancellationError()))
            }
        }
    }
}
