//
//  ContextAPIWrapper.swift
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
 * Wrapper class that provides safe access to the Context API module.
 */
class ContextAPIWrapper: ContextAPI {
    private let moduleProxy: ModuleProxy<ContextAPIModule, ContextAPIError>

    init(moduleProxy: ModuleProxy<ContextAPIModule, ContextAPIError>) {
        self.moduleProxy = moduleProxy
    }

    @discardableResult
    func fetchEngineResponse(engineID: String) -> SingleResult<EngineResponse, ModuleError<ContextAPIError>> {
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
