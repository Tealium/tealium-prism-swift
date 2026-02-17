//
//  MomentsAPI.swift
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
 * The Moments API module retrieves visitor profile data from Tealium AudienceStream.
 */
public protocol MomentsAPI {
    /**
     * Fetches visitor data from a configured Moments API Engine.
     * 
     * - Parameters:
     *   - engineID: The ID of the Moments API engine to fetch data from
     * - Returns: A `SingleResult` that can be subscribed upon to receive `EngineResponse` or error.
     */
    @discardableResult
    func fetchEngineResponse(engineID: String) -> SingleResult<EngineResponse, ModuleError<MomentsAPIError>>
}
