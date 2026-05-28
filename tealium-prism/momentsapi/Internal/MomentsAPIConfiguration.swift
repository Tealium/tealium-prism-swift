//
//  MomentsAPIConfiguration.swift
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
 * Configuration struct for the Moments API module.
 */
struct MomentsAPIConfiguration {
    /// The region for the Moments API requests (required).
    let region: MomentsAPIRegion
    /// The referrer URL for the Moments API requests (optional, can be generated if not provided).
    let referrer: String?

    enum Keys {
        static let region = "moments_api_region"
        static let referrer = "moments_api_referrer"
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
        self.init(region: MomentsAPIRegion(rawValue: regionValue) ?? .custom(regionValue),
                  referrer: configuration.get(key: Keys.referrer))
    }

    init(region: MomentsAPIRegion, referrer: String?) {
        self.region = region
        self.referrer = referrer
    }
}
