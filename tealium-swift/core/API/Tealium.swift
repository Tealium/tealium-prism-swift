//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias TrackResultCompletion = (_ dispatch: TealiumDispatch, _ result: TrackResult) -> Void

/// An error happened during `Tealium` initialization process. Use the `underlyingError` to understand the root cause.
struct TealiumInitializationError: Error {
    let underlyingError: Error?
}
public class Tealium {
    let modulesManager: ModulesManager
    private var onTealiumImplementation = ReplaySubject<TealiumImplementation?>()
    let automaticDisposer = AutomaticDisposer()
    let queue = TealiumQueue.worker
    var initializationError: Error?
    public init(_ config: TealiumConfig, completion: @escaping (Result<Tealium, Error>) -> Void) {
        let startupInterval = TealiumSignpostInterval(signposter: .startup, name: "Teal Init")
            .begin()
        let modulesManager = ModulesManager(queue: queue)
        self.modulesManager = modulesManager
        trace = TealiumTrace(modulesManager: modulesManager)
        deepLink = TealiumDeepLink(modulesManager: modulesManager)
        dataLayer = TealiumDataLayer(modulesManager: modulesManager)
        timedEvents = TealiumTimedEvents()
        consent = TealiumConsent()
        queue.ensureOnQueue {
            do {
                let tealiumImplementation = try TealiumImplementation(config, modulesManager: modulesManager)
                startupInterval.end()
                self.onTealiumImplementation.publish(tealiumImplementation)
                completion(.success(self))
            } catch {
                startupInterval.end()
                self.initializationError = error
                self.onTealiumImplementation.publish(nil)
                completion(.failure(error))
            }
        }
    }

    private func onImplementationReady(_ completion: @escaping (Result<TealiumImplementation, TealiumInitializationError>) -> Void) {
        onTealiumImplementation
            .subscribeOn(queue)
            .map { implementation in
                if let implementation {
                    Result.success(implementation)
                } else {
                    Result.failure(TealiumInitializationError(underlyingError: self.initializationError))
                }
            }
            .subscribeOnce(completion)
            .addTo(automaticDisposer)
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

    private func onTealiumSuccess<T>(completion: ((Result<T, Error>) -> Void)?, execute: @escaping (TealiumImplementation) throws -> T) {
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

    public let trace: TealiumTrace

    public let deepLink: TealiumDeepLink

    public let dataLayer: TealiumDataLayer

    public let timedEvents: TealiumTimedEvents

    public let consent: TealiumConsent

    public func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void) {
        modulesManager.getModule(completion: completion)
    }
}
