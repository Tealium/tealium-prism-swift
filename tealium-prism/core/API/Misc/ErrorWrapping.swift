//
//  ErrorWrapping.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 21/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// An error that can be created with an underlying error of a specific type.
public protocol ErrorWrapping<SomeError>: Error {
    associatedtype SomeError: Error
    /// Creates an `ErrorWrapping` error with the given underlying error.
    /// Usually this can be a case in an error enum.
    static func underlyingError(_ error: SomeError) -> Self
}

public extension ErrorWrapping {
    /**
     * Wraps the eventual errors thrown by the given block.
     *
     * - parameter block: The throwing block that can throw `SomeError`, which will be wrapped into an `ErrorWrapping`.
     * - throws: An `ErrorWrapping` that wraps the underlying error.
     */
    static func wrapErrors<T>(block: () throws(SomeError) -> T) throws(Self) -> T {
        do {
            return try block()
        } catch {
            if let selfError = error as? Self {
                // if error is of type Self there's no need to wrap it
                throw selfError
            } else {
                throw self.underlyingError(error)
            }
        }
    }
}
