//
//  ContextAPIModule.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if contextapi
import TealiumPrismCore
#endif

/**
 * Internal Context API module implementation.
 */
class ContextAPIModule: BasicModule {
    static let moduleType: String = Modules.Types.contextAPI

    let version: String = TealiumConstants.libraryVersion
    var id: String { Self.moduleType }

    /// Looks up the `VisitorIdProvider`, calling the completion with it, or with `nil` if visitor ID handling is disabled.
    typealias VisitorIdProviderLookup = (_ completion: @escaping (VisitorIdProvider?) -> Void) -> any Disposable

    private let service: ContextAPIService
    private let getVisitorIdProvider: VisitorIdProviderLookup
    private let logger: LoggerProtocol?
    private var configuration: ContextAPIConfiguration
    /**
     * Requests still waiting for the visitor ID or the network. Failed when this module shuts down.
     *
     * Automatic, so a module that is released without a `shutdown` still fails its pending requests
     * instead of leaving their callers waiting forever.
     */
    private let pendingRequests = Disposables.automatic()

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let configuration = ContextAPIConfiguration(configuration: moduleConfiguration) else {
            context.logger?.warn(category: Self.moduleType,
                                 "Context API module cannot be created: region is required but missing from configuration")
            return nil
        }
        // Bounded retries with the default `RequestInterceptors.retryWithBackoff()`; never waits for connectivity.
        let client = context.network.networkClient.newClient(withAdditionalInterceptors: [RequestInterceptors.retryWithBackoff()])
        let service = ContextAPIService(
            networkHelper: client.makeNetworkHelper(),
            account: context.config.account,
            profile: context.config.profile,
            environment: context.config.environment,
            configuration: configuration
        )
        // Weak, as the ModuleManager owns this module
        let getVisitorIdProvider: VisitorIdProviderLookup = { [weak moduleManager = context.moduleManager] completion in
            guard let moduleManager else {
                completion(nil)
                return Disposables.disposed()
            }
            return moduleManager.getModule(transform: { $0 as? VisitorIdProvider }, completion: completion)
        }
        self.init(service: service, getVisitorIdProvider: getVisitorIdProvider, logger: context.logger, configuration: configuration)
    }

    init(service: ContextAPIService,
         getVisitorIdProvider: @escaping VisitorIdProviderLookup,
         logger: LoggerProtocol?,
         configuration: ContextAPIConfiguration) {
        self.service = service
        self.logger = logger
        self.getVisitorIdProvider = getVisitorIdProvider
        self.configuration = configuration
        logger?.trace(category: LogCategory.contextAPI, "Context API module initialized with region: \(self.configuration.region.rawValue)")
    }

    // MARK: - Internal API

    /**
     * Fetches the engine response for the current visitor.
     *
     * - Parameters:
     *   - engineID: The ID of the Context API engine to fetch data from.
     *   - completion: Called exactly once. Fails with `ModuleError.moduleNotEnabled` when visitor ID
     *   handling is disabled, with `ModuleError.moduleShutdown` when this module is shut down before
     *   the request completes, or with `ModuleError.underlyingError` wrapping the service failure.
     */
    func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, ModuleError<ContextAPIError>>) -> Void) {
        // Once only: disposing a request both fires its shutdown guard and cancels its network call.
        let completion = SelfDestructingResultCompletion(completion: completion)
        let pending = Disposables.composite()
        // Disposed by shutdown, which fails the requests that are never going to complete.
        Disposables.subscription { [id] in
            completion.fail(error: .moduleShutdown(id))
        }.addTo(pending)
        pendingRequests.add(pending)
        // Already shut down: `add` disposed `pending`, so the guard above already failed this request.
        guard !pending.isDisposed else { return }
        getVisitorIdProvider { [weak self, id] visitorIdProvider in
            // Released without a shutdown: there is no module left to fetch with.
            guard let self else {
                completion.fail(error: .moduleShutdown(id))
                return
            }
            guard let visitorIdProvider else {
                self.pendingRequests.remove(pending)
                self.logger?.error(category: LogCategory.contextAPI,
                                   "Failed to fetch Context API response: visitor ID handling is disabled")
                completion.fail(error: .moduleNotEnabled(Modules.Types.visitorId))
                return
            }
            self.fetchEngineResponse(engineID: engineID, visitorID: visitorIdProvider.visitorId.value) { [weak self] result in
                // Cancelled by shutdown: the shutdown guard already failed this request.
                guard !pending.isDisposed else { return }
                // Drops the shutdown guard: removing does not dispose, so it can no longer fire.
                self?.pendingRequests.remove(pending)
                self?.logResult(result)
                completion.complete(result: result.mapError { .underlyingError($0) })
            }.addTo(pending)
        }.addTo(pending)
    }

    private func fetchEngineResponse(engineID: String,
                                     visitorID: String,
                                     completion: @escaping (Result<EngineResponse, ContextAPIError>) -> Void) -> any Disposable {
        logger?.trace(category: LogCategory.contextAPI, "Fetching Context API response for engine: \(engineID), visitor: \(visitorID)")
        return service.fetchEngineResponse(engineID: engineID, visitorID: visitorID, completion: completion)
    }

    private func logResult(_ result: Result<EngineResponse, ContextAPIError>) {
        switch result {
        case .success(let response):
            logger?.trace(category: LogCategory.contextAPI, "Successfully fetched Context API response: \(response)")
        case .failure(let error):
            logger?.error(category: LogCategory.contextAPI, "Failed to fetch Context API response: \(error)")
        }
    }

    // MARK: - Module Protocol

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        guard let newConfiguration = ContextAPIConfiguration(configuration: configuration) else {
            logger?.warn(category: id,
                         "Context API module configuration update failed: region is required but missing from configuration")
            // Return nil to disable the module when configuration is invalid
            return nil
        }
        self.configuration = newConfiguration
        service.updateConfiguration(self.configuration)
        return self
    }

    func shutdown() {
        // Fails the requests that are still in progress, instead of leaving their callers hanging.
        pendingRequests.dispose()
    }
}
