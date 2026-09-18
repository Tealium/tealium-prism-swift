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

    private let service: ContextAPIService
    private let visitorId: ObservableState<String>
    private let logger: LoggerProtocol?
    private var configuration: ContextAPIConfiguration
    private let disposables = Disposables.automatic()

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let configuration = ContextAPIConfiguration(configuration: moduleConfiguration) else {
            context.logger?.warn(category: Self.moduleType,
                                 "Context API module cannot be created: region is required but missing from configuration")
            return nil
        }
        // Initialize service using NetworkHelper from context
        // This allows tests to inject mock helpers via config.networkClient -> TealiumImpl -> NetworkHelper
        let service = ContextAPIService(
            networkHelper: context.network.networkHelper,
            account: context.config.account,
            profile: context.config.profile,
            environment: context.config.environment,
            configuration: configuration
        )
        self.init(service: service, visitorId: context.visitorId, logger: context.logger, configuration: configuration)
    }

    init(service: ContextAPIService,
         visitorId: ObservableState<String>,
         logger: LoggerProtocol?,
         configuration: ContextAPIConfiguration) {
        self.service = service
        self.logger = logger
        self.visitorId = visitorId
        self.configuration = configuration
        logger?.trace(category: LogCategory.contextAPI, "Context API module initialized with region: \(self.configuration.region.rawValue)")
    }

    // MARK: - Internal API

    func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, ContextAPIError>) -> Void) {
        let visitorID = visitorId.value

        logger?.trace(category: LogCategory.contextAPI, "Fetching Context API response for engine: \(engineID), visitor: \(visitorID)")

        service.fetchEngineResponse(engineID: engineID, visitorID: visitorID) { [weak self] result in
            switch result {
            case .success(let response):
                self?.logger?.trace(category: LogCategory.contextAPI, "Successfully fetched Context API response: \(response)")
                completion(.success(response))
            case .failure(let error):
                self?.logger?.error(category: LogCategory.contextAPI, "Failed to fetch Context API response: \(error)")
                completion(.failure(error))
            }
        }.addTo(disposables)
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
        disposables.dispose()
    }
}
