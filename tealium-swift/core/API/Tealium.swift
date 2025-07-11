//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// Completion handler for tracking operations that provides the result with either dropped or accepted dispatch.
public typealias TrackResultCompletion = (_ result: TrackResult) -> Void

/**
 * The main class for the Tealium SDK.
 *
 * This class provides the primary interface for interacting with the Tealium SDK.
 * It handles initialization, tracking events, managing visitor IDs, and accessing
 * various modules like data layer, deep linking, and tracing.
 */
public class Tealium {
    /// Result type for Tealium initialization operations.
    public typealias InitializationResult = Result<Tealium, TealiumError>

    /// Result type for internal implementation operations.
    typealias ImplementationResult = Result<TealiumImpl, TealiumError>

    /// Observable type for `ImplementationResult`.
    typealias ImplementationObservable = Observable<ImplementationResult>

    /// Observable for the modules manager.
    private let onModulesManager: Observable<ModulesManager?>

    /// Disposer for async operations.
    private lazy var asyncDisposer = AsyncDisposer(disposeOn: queue)

    /// Queue for Tealium operations.
    let queue: TealiumQueue

    /// The proxy used to access `TealiumImpl` from the right thread.
    let proxy: AsyncProxy<TealiumImpl>

    /**
     * Creates a new Tealium instance with the provided configuration.
     *
     * - Parameters:
     *   - config: The configuration for the Tealium instance.
     *   - completion: A closure that is called when initialization completes, providing either the Tealium instance or an error.
     * - Returns: A new Tealium instance.
     */
    public static func create(config: TealiumConfig, completion: ((InitializationResult) -> Void)? = nil) -> Tealium {
        TealiumInstanceManager.shared.create(config: config, completion: completion)
    }

    /**
     * Initializes a new Tealium instance with the provided implementation observable.
     *
     * - Parameter onTealiumImplementation: An observable that emits the Tealium `ImplementationResult`.
     */
    init(queue: TealiumQueue, onTealiumImplementation: ImplementationObservable) {
        self.queue = queue
        onModulesManager = onTealiumImplementation.map { result in
            if case .success(let implementation) = result {
                return implementation.modulesManager
            } else {
                return nil
            }
        }
        proxy = AsyncProxy(queue: queue,
                           onObject: onTealiumImplementation.map { $0.mapError { $0 as Error } })
    }

    /**
     * Executes the provided completion handler when `Tealium` is ready for use, from the `Tealium` internal thread.
     *
     * Usage of this method is incentivised in case you want to call multiple `Tealium` methods in a row.
     * Every one of those methods, if called from a different thread, will cause the execution to move into our
     * own internal queue, causing overhead.
     * Calling those methods from the completion of this method, instead, will skip all of those context switches
     * and perform the operations synchronously onto our thread.
     *
     * - Parameter completion: A closure that is called with the `Tealium` instance when it's ready.
     * In case of an initialization error the completion won't be called at all.
     */
    public func onReady(_ completion: @escaping (Tealium) -> Void) {
        proxy.getProxiedObject { [weak self] _ in
            guard let self else { return }
            completion(self)
        }
    }

    /**
     * Tracks an event with the specified name, type, and data.
     *
     * - Parameters:
     *   - name: The name of the event to track.
     *   - type: The type of dispatch to use (default is .event).
     *   - data: Additional data to include with the event (optional).
     *
     * - returns: A `Single` onto which you can subscribe to receive the completion with the eventual error
     * or the `TrackResult` for this track request.
     */
    @discardableResult
    public func track(_ name: String, type: DispatchType = .event, data: DataObject? = nil) -> SingleResult<TrackResult> {
        let dispatch = Dispatch(name: name, type: type, data: data)
        return proxy.executeAsyncTask { tealium, completion in
            tealium.track(dispatch) { result in
                completion(.success(result))
            }
        }
    }

    /**
     * Flushes any queued events from the system when it is considered safe to do so by any `Barrier`s
     * that may be blocking, i.e. when their `isFlushable` returns `true`.
     *
     * - Attention: This method will not override those `Barrier` implementations whose `isFlushable`
     * returns `false`. But when non-flushable barriers open, a flush will still occur.
     *
     * - returns: A `Single` onto which you can subscribe to receive the completion with the eventual error.
     * The returned `Single`, in case of success, completes when the flush request is accepted, not when all the events have been flushed.
     */
    @discardableResult
    public func flushEventQueue() -> SingleResult<Void> {
        proxy.executeTask { tealium in
            tealium.barrierCoordinator.flush()
        }
    }

    /**
     * Resets the current visitor ID to a new anonymous one.
     *
     * Note. the new anonymous ID will be associated to any identity currently set.
     *
     * - returns: A `Single` onto which you can subscribe to receive the completion with the eventual error
     * or the new visitor ID.
     */
    @discardableResult
    public func resetVisitorId() -> SingleResult<String> {
        proxy.executeTask { tealium in
            try tealium.visitorIdProvider.resetVisitorId()
        }
    }

    /**
     * Removes all stored visitor identifiers as hashed identities, and generates a new
     * anonymous visitor ID.
     *
     * - returns: A `Single` onto which you can subscribe to receive the completion with the eventual error
     * or the new visitor ID.
     */
    @discardableResult
    public func clearStoredVisitorIds() -> SingleResult<String> {
        proxy.executeTask { tealium in
            try tealium.visitorIdProvider.clearStoredVisitorIds()
        }
    }

    /// Manager for trace-related functionality.
    public private(set) lazy var trace: TraceManager = TraceManagerWrapper(moduleProxy: createModuleProxy())

    /// Manager for deep link functionality.
    public private(set) lazy var deepLink: DeepLinkHandler = DeepLinkHandlerWrapper(moduleProxy: createModuleProxy())

    /// Interface for accessing and manipulating the data layer.
    public private(set) lazy var dataLayer: DataLayer = DataLayerWrapper(moduleProxy: createModuleProxy())

    /**
     * Creates a `ModuleProxy` for the given module to allow for an easy creation of Module Wrappers.
     *
     * This method should only be used when creating a `Module` wrapper. Use the already prebuilt wrappers for modules included in the SDK.
     *
     * - Parameters:
     *   - module: The `Module` type that the Proxy needs to wrap.
     * - Returns: The `ModuleProxy` for the given module.
     */
    public func createModuleProxy<T: Module>(for module: T.Type = T.self) -> ModuleProxy<T> {
        ModuleProxy(onModulesManager: onModulesManager)
    }

    deinit {
        asyncDisposer.dispose()
        queue.ensureOnQueue { [proxy = self.proxy] in // Avoid capturing self in deinit
            // Hold an extra reference to `TealiumImpl` to make sure that it,
            // and all its dependencies, are only deallocated from the right thread.
            _ = proxy
        }
    }
}
