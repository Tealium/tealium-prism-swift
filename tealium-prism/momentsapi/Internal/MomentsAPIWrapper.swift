//
//  MomentsAPIWrapper.swift
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
 * Wrapper class that provides safe access to the Moments API module.
 */
class MomentsAPIWrapper: MomentsAPI {
    private let moduleProxy: ModuleProxy<MomentsAPIModule, MomentsAPIError>

    init(moduleProxy: ModuleProxy<MomentsAPIModule, MomentsAPIError>) {
        self.moduleProxy = moduleProxy
    }

    @discardableResult
    func fetchEngineResponse(engineID: String) -> SingleResult<EngineResponse, ModuleError<MomentsAPIError>> {
        moduleProxy.executeAsyncModuleTask { module, completion in
            module.fetchEngineResponse(engineID: engineID) { result in
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let error):
                    completion(.failure(ModuleError.underlyingError(error)))
                }
            }
        }
    }
}
