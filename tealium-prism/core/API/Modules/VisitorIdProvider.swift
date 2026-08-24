//
//  VisitorIdProvider.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 24/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/**
 * A namespaced view over the SDK's visitor ID logic: read, reset, clear, and observe the visitor ID.
 *
 * Access it via `Tealium.visitorIdProvider`. Unlike pluggable features such as `trace` or `deepLink`,
 * this is always-on core plumbing, backed by a `Module` that cannot be disabled.
 */
public protocol VisitorIdProvider {

    /**
     * Retrieves the current visitor ID.
     *
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the current
     * visitor ID or the eventual error.
     */
    func getVisitorId() -> SingleResult<String, ModuleError<Error>>

    /**
     * Resets the current visitor ID to a new anonymous one.
     *
     * Note. the new anonymous ID will be associated to any identity currently set.
     *
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the new
     * visitor ID or the eventual error.
     */
    @discardableResult
    func reset() -> SingleResult<String, ModuleError<Error>>

    /**
     * Removes all stored visitor identifiers as hashed identities, and generates a new anonymous
     * visitor ID.
     *
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the new
     * visitor ID or the eventual error.
     */
    @discardableResult
    func clearStored() -> SingleResult<String, ModuleError<Error>>

    /**
     * An observable that emits the current visitor ID on subscription and every subsequent change.
     *
     * Emissions are delivered on the internal Tealium queue.
     */
    var onVisitorId: any Subscribable<String> { get }
}
