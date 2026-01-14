//
//  MomentsAPIService.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if momentsapi
import TealiumPrismCore
#endif

/**
 * Internal service class that handles HTTP requests to the Moments API.
 */
class MomentsAPIService {
    private let networkHelper: NetworkHelperProtocol
    private let account: String
    private let profile: String
    private let environment: String
    private var configuration: MomentsAPIConfiguration

    init(networkHelper: NetworkHelperProtocol, account: String, profile: String, environment: String, configuration: MomentsAPIConfiguration) {
        self.networkHelper = networkHelper
        self.account = account
        self.profile = profile
        self.environment = environment
        self.configuration = configuration
    }

    func updateConfiguration(_ configuration: MomentsAPIConfiguration) {
        self.configuration = configuration
    }

    /**
     * Fetches visitor data from the Moments API engine.
     *
     * - Parameters:
     *   - engineID: The ID of the Moments API engine
     *   - visitorID: The visitor ID to fetch data for
     *   - completion: Completion handler with the result
     * - Returns: A `Disposable` that can be used to cancel the request
     */
    @discardableResult
    func fetchEngineResponse(engineID: String, visitorID: String, completion: @escaping (Result<EngineResponse, MomentsAPIError>) -> Void) -> Disposable {
        guard !engineID.isEmpty else {
            completion(.failure(MomentsAPIError.invalidEngineID))
            return Disposables.disposed()
        }

        guard let url = buildURL(engineID: engineID, visitorID: visitorID) else {
            let errorMessage = "Failed to build Moments API URL"
            completion(.failure(MomentsAPIError.configurationError(errorMessage)))
            return Disposables.disposed()
        }

        let referrerValue = configuration.referrer ?? "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html"
        let headers = [
            "Accept": "application/json",
            "Referer": referrerValue
        ]

        return networkHelper.getJsonAsObject(url: url, additionalHeaders: headers) { (result: ObjectResult<EngineResponse>) in
            switch result {
            case .success(let response):
                completion(.success(response.object))
            case .failure(let error):
                completion(.failure(MomentsAPIError.networkError(error)))
            }
        }
    }

    private func buildURL(engineID: String, visitorID: String) -> URL? {
        let baseURL = "https://personalization-api.\(configuration.region.rawValue).prod.tealiumapis.com/" +
            "personalization/accounts/\(account)/profiles/\(profile)/engines/\(engineID)/" +
            "visitors/\(visitorID)?ignoreTapid=true"
        return URL(string: baseURL)
    }
}
