//
//  ContextAPIConfiguration.swift
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
 * Configuration struct for the Context API module.
 */
struct ContextAPIConfiguration {
    /// The region for the Context API requests (required).
    let region: ContextAPIRegion
    /// The referrer URL for the Context API requests (optional, can be generated if not provided).
    let referrer: String?

    enum Keys {
        static let region = "context_api_region"
        static let referrer = "context_api_referrer"
    }

    /**
     * Initializes the configuration from a DataObject.
     * 
     * - Parameter configuration: The DataObject containing the configuration
     * - Returns: nil if the required region is missing
     */
    init?(configuration: DataObject) {
        guard let regionValue = configuration.get(key: Keys.region, as: String.self) else {
            return nil
        }
        // Always creates a region - if it doesn't match predefined regions, creates a custom one
        self.init(region: ContextAPIRegion(rawValue: regionValue) ?? .custom(regionValue),
                  referrer: configuration.get(key: Keys.referrer))
    }

    init(region: ContextAPIRegion, referrer: String?) {
        self.region = region
        self.referrer = referrer
    }
}
