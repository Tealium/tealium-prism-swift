//
//  Single.swift
//  Pods
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A `Subscribable` implementation whereby only a single result is expected to be emitted to the subscriber.
public protocol Single<Element>: Subscribable { }

class SingleImpl<Element>: Single {
    private let subscribable: any Subscribable<Element>
    init(observable: Observable<Element>, queue: TealiumQueue) {
        self.subscribable = observable
            .first()
            .subscribeOn(queue)
    }

    func subscribe(_ observer: @escaping Observer) -> any Disposable {
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
    associatedtype ErrorType: Error
    /// - Returns: An error, if it's present in the object, or nil.
    func getError() -> ErrorType?
}

/// An object from which you can extract an optional value.
public protocol ValueExtractor<ValueType> {
    associatedtype ValueType
    /// - Returns: The value, if it's present in the object, or nil.
    func getValue() -> ValueType?
}

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
    func onSuccess<Value>(handler: @escaping (Value) -> Void) -> Disposable where Element: ValueExtractor<Value> {
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
    func onFailure<ErrorType>(handler: @escaping (ErrorType) -> Void) -> Disposable where Element: ErrorExtractor<ErrorType> {
        subscribe { result in
            if let error = result.getError() {
                handler(error)
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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
