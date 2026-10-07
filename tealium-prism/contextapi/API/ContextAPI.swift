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
     * The failure is a [`ModuleError.moduleNotEnabled(_:)`](doc:ModuleError/moduleNotEnabled(_:)) when the
     * ContextAPI module is not enabled, or when the VisitorId module is disabled, as fetching requires the
     * visitor ID. It is a [`ModuleError.moduleShutdown(_:)`](doc:ModuleError/moduleShutdown(_:)) when the
     * ContextAPI module was shut down before the request completed, or a
     * [`ModuleError.underlyingError(_:)`](doc:ModuleError/underlyingError(_:)) wrapping the `ContextAPIError`
     * that stopped the request.
     *
     * - Parameters:
     *   - engineID: The ID of the Context API engine to fetch data from
     * - Returns: A `SingleResult` that can be subscribed upon to receive `EngineResponse` or error.
     */
    @discardableResult
    func fetchEngineResponse(engineID: String) -> SingleResult<EngineResponse, ModuleError<ContextAPIError>>
}
