//
//  Single.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A `Subscribable` implementation whereby only a single result is expected to be emitted to the subscriber.
public protocol Single<Element>: Subscribable {
    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> any Disposable
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
public typealias SingleResult<T> = any Single<Result<T, Error>>

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
    func onSuccess<Value>(handler: @escaping (_ output: Value) -> Void) -> Disposable where Element: ValueExtractor<Value> {
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
    func onFailure<ErrorType>(handler: @escaping (_ error: ErrorType) -> Void) -> Disposable where Element: ErrorExtractor<ErrorType> {
        subscribe { result in
            if let error = result.getError() {
                handler(error)
            }
        }
    }
}

public extension Single {
    /// Transforms this single into an async function that can be awaited on.
    func toAsync<Value>() async throws -> Value where Element == Result<Value, Error> {
        try await withCheckedThrowingContinuation { continuation in
            _ = self.subscribe { result in
                continuation.resume(with: result)
            }
        }
    }
}
