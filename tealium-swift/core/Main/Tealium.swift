//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class Tealium {
    let modulesManager: ModulesManager
    private var onTealiumImplementation = TealiumReplaySubject<TealiumImplementation?>()
    let automaticDisposer = TealiumAutomaticDisposer()

    public init(_ config: TealiumConfig, completion: @escaping (Result<Tealium, Error>) -> Void) {
        let startupInterval = TealiumSignpostInterval(signposter: .startup, name: "Teal Init")
            .begin()
        let modulesManager = ModulesManager()
        self.modulesManager = modulesManager
        trace = TealiumTrace(modulesManager: modulesManager)
        deepLink = TealiumDeepLink(modulesManager: modulesManager)
        dataLayer = TealiumDataLayer(modulesManager: modulesManager)
        timedEvents = TealiumTimedEvents()
        consent = TealiumConsent()
        tealiumQueue.async {
            do {
                let tealiumImplementation = try TealiumImplementation(config, modulesManager: modulesManager)
                startupInterval.end()
                self.onTealiumImplementation.publish(tealiumImplementation)
                completion(.success(self))
            } catch {
                startupInterval.end()
                self.onTealiumImplementation.publish(nil)
                completion(.failure(error))
            }
        }
    }

    private func onImplementationReady(_ completion: @escaping (TealiumImplementation?) -> Void) {
        onTealiumImplementation
            .subscribeOn(tealiumQueue)
            .subscribeOnce(completion)
            .addTo(automaticDisposer)
    }

    public func onReady(_ completion: @escaping (Tealium) -> Void) {
        onImplementationReady { [weak self] implementation in
            if implementation != nil, let self = self {
                completion(self)
            }
        }
    }

    public func track(_ name: String, type: DispatchType = .event, data: TealiumDictionaryInput? = nil) {
        let dispatch = TealiumDispatch(name: name, type: type, data: data)
        onImplementationReady { implementation in
            implementation?.track(dispatch)
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
