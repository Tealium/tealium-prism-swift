//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias TrackResultCompletion = (_ dispatch: TealiumDispatch, _ result: TrackResult) -> Void

public class Tealium {
    public typealias InitializationResult = Result<Tealium, TealiumError>
    typealias ImplementationResult = Result<TealiumImpl, TealiumError>
    typealias ImplementationObservable = Observable<ImplementationResult>
    private let onModulesManager: Observable<ModulesManager?>
    private let onTealiumImplementation: ImplementationObservable
    let asyncDisposer = AsyncDisposer(disposeOn: .worker)
    let queue = TealiumQueue.worker
    var initializationError: TealiumError?

    public static func create(config: TealiumConfig, completion: @escaping (InitializationResult) -> Void) -> Tealium {
        TealiumInstanceManager.shared.create(config: config, completion: completion)
    }

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

    private func onImplementationReady(_ completion: @escaping (ImplementationResult) -> Void) {
        onTealiumImplementation
            .first()
            .subscribeOn(queue)
            .subscribe(completion)
            .addTo(asyncDisposer)
    }

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

    public func track(_ name: String, type: DispatchType = .event, data: DataObject? = nil, onTrackResult: TrackResultCompletion? = nil) {
        let dispatch = TealiumDispatch(name: name, type: type, data: data)
        onImplementationReady { result in
            switch result {
            case .success(let implementation):
                implementation.track(dispatch, onTrackResult: onTrackResult)
            case .failure:
                onTrackResult?(dispatch, TrackResult.dropped)
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

    public private(set) lazy var trace: TealiumTrace = TealiumTrace(moduleProxy: createModuleProxy())

    public private(set) lazy var deepLink: TealiumDeepLink = TealiumDeepLink(moduleProxy: createModuleProxy())

    public private(set) lazy var dataLayer: DataLayer = DataLayerWrapper(moduleProxy: createModuleProxy())

    public let timedEvents: TealiumTimedEvents

    /**
     * Creates a `ModuleProxy` for the given module to allow for an easy creation of Module Wrappers.
     *
     * This method should only be used when creating a `Module` wrapper. Use the already prebuilt wrappers for modules included in the SDK.
     *
     * - Parameters:
     *      - module: The `Module` type that the Proxy needs to wrap.
     * - Returns: The `ModuleProxy` for the given module.
     */
    public func createModuleProxy<T: TealiumModule>(for module: T.Type = T.self) -> ModuleProxy<T> {
        ModuleProxy(onModulesManager: onModulesManager)
    }

    deinit {
        asyncDisposer.dispose()
        queue.ensureOnQueue { [onTealiumImplementation = self.onTealiumImplementation] in // Avoid capturing self in deinit
            // Hold an extra reference to `TeliumImpl` to make sure that it,
            // and all its dependencies, are only deallocated from the right thread.
            _ = onTealiumImplementation
        }
    }
}
