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

    /// Observable type for implementation results.
    typealias ImplementationObservable = Observable<ImplementationResult>

    /// Observable for the modules manager.
    private let onModulesManager: Observable<ModulesManager?>

    /// Observable for the Tealium implementation.
    private let onTealiumImplementation: ImplementationObservable

    /// Disposer for async operations.
    let asyncDisposer = AsyncDisposer(disposeOn: .worker)

    /// Queue for Tealium operations.
    let queue = TealiumQueue.worker

    /// Error that occurred during initialization, if any.
    var initializationError: TealiumError?

    /**
     * Creates a new Tealium instance with the provided configuration.
     *
     * - Parameters:
     *   - config: The configuration for the Tealium instance.
     *   - completion: A closure that is called when initialization completes, providing either the Tealium instance or an error.
     * - Returns: A new Tealium instance.
     */
    public static func create(config: TealiumConfig, completion: @escaping (InitializationResult) -> Void) -> Tealium {
        TealiumInstanceManager.shared.create(config: config, completion: completion)
    }

    /**
     * Initializes a new Tealium instance with the provided implementation observable.
     *
     * - Parameter onTealiumImplementation: An observable that emits the Tealium implementation result.
     */
    init(onTealiumImplementation: ImplementationObservable) {
        onModulesManager = onTealiumImplementation.map { result in
            if case .success(let implementation) = result {
                return implementation.modulesManager
            } else {
                return nil
            }
        }
        timedEvents = TealiumTimedEvents()
        self.onTealiumImplementation = onTealiumImplementation
    }

    /**
     * Executes the provided completion handler when the implementation is ready.
     *
     * - Parameter completion: A closure that is called with the implementation result.
     */
    private func onImplementationReady(_ completion: @escaping (ImplementationResult) -> Void) {
        onTealiumImplementation
            .first()
            .subscribeOn(queue)
            .subscribe(completion)
            .addTo(asyncDisposer)
    }

    /**
     * Executes the provided completion handler when Tealium is ready for use.
     *
     * - Parameter completion: A closure that is called with the Tealium instance when it's ready.
     */
    public func onReady(_ completion: @escaping (Tealium) -> Void) {
        onImplementationReady { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                completion(self)
            case .failure:
                break
            }
        }
    }

    /**
     * Tracks an event with the specified name, type, and data.
     *
     * - Parameters:
     *   - name: The name of the event to track.
     *   - type: The type of dispatch to use (default is .event).
     *   - data: Additional data to include with the event (optional).
     *   - onTrackResult: A closure that is called with the result of the tracking operation (optional).
     */
    public func track(_ name: String, type: DispatchType = .event, data: DataObject? = nil, onTrackResult: TrackResultCompletion? = nil) {
        let dispatch = TealiumDispatch(name: name, type: type, data: data)
        onImplementationReady { result in
            switch result {
            case .success(let implementation):
                implementation.track(dispatch, onTrackResult: onTrackResult)
            case .failure:
                onTrackResult?(TrackResult.dropped(dispatch))
            }
        }
    }

    /**
     * Resets the current visitor id to a new anonymous one.
     *
     * Note. the new anonymous id will be associated to any identity currently set.
     *
     * - Parameters:
     *   - completion: The block called with the new `visitorId`, if successful, or an error.
     */
    public func resetVisitorId(completion: ((Result<String, Error>) -> Void)? = nil) {
        onTealiumSuccess(completion: completion) { implementation in
            try implementation.visitorIdProvider.resetVisitorId()
        }
    }

    /**
     * Removes all stored visitor identifiers as hashed identities, and generates a new
     * anonymous visitor id.
     *
     * - Parameters:
     *   - completion: The block called with the new `visitorId`, if successful, or an error.
     */
    public func clearStoredVisitorIds(completion: ((Result<String, Error>) -> Void)? = nil) {
        onTealiumSuccess(completion: completion) { implementation in
            try implementation.visitorIdProvider.clearStoredVisitorIds()
        }
    }

    /**
     * Executes a function on the Tealium implementation and handles the result.
     *
     * - Parameters:
     *   - completion: A closure that is called with the result of the operation.
     *   - execute: A closure that performs an operation on the Tealium implementation.
     */
    private func onTealiumSuccess<T>(completion: ((Result<T, Error>) -> Void)?, execute: @escaping (TealiumImpl) throws -> T) {
        onImplementationReady { result in
            do {
                switch result {
                case .success(let implementation):
                    let newObject = try execute(implementation)
                    completion?(.success(newObject))
                case .failure(let error):
                    completion?(.failure(error))
                }
            } catch {
                completion?(.failure(error))
            }
        }
    }

    /// Manager for trace-related functionality.
    public private(set) lazy var trace: TraceManager = TraceManagerWrapper(moduleProxy: createModuleProxy())

    /// Manager for deep link functionality.
    public private(set) lazy var deepLink: DeepLinkHandler = DeepLinkHandlerWrapper(moduleProxy: createModuleProxy())

    /// Interface for accessing and manipulating the data layer.
    public private(set) lazy var dataLayer: DataLayer = DataLayerWrapper(moduleProxy: createModuleProxy())

    /// Manager for timed events.
    public let timedEvents: TealiumTimedEvents

    /**
     * Creates a `ModuleProxy` for the given module to allow for an easy creation of Module Wrappers.
     *
     * This method should only be used when creating a `Module` wrapper. Use the already prebuilt wrappers for modules included in the SDK.
     *
     * - Parameters:
     *   - module: The `Module` type that the Proxy needs to wrap.
     * - Returns: The `ModuleProxy` for the given module.
     */
    public func createModuleProxy<T: TealiumModule>(for module: T.Type = T.self) -> ModuleProxy<T> {
        ModuleProxy(onModulesManager: onModulesManager)
    }

    deinit {
        asyncDisposer.dispose()
        queue.ensureOnQueue { [onTealiumImplementation = self.onTealiumImplementation] in // Avoid capturing self in deinit
            // Hold an extra reference to `TealiumImpl` to make sure that it,
            // and all its dependencies, are only deallocated from the right thread.
            _ = onTealiumImplementation
        }
    }
}
