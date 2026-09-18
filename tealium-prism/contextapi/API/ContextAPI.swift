//
//  ContextAPI.swift
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
 * The Context API module retrieves visitor profile data from Tealium AudienceStream.
 */
public protocol ContextAPI {
    /**
     * Fetches visitor data from a configured Context API Engine.
     * 
     * - Parameters:
     *   - engineID: The ID of the Context API engine to fetch data from
     * - Returns: A `SingleResult` that can be subscribed upon to receive `EngineResponse` or error.
     */
    @discardableResult
    func fetchEngineResponse(engineID: String) -> SingleResult<EngineResponse, ModuleError<ContextAPIError>>
}
