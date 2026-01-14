//
//  MomentsAPISettingsBuilder.swift
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
 * Builder for Moments API module settings.
 */
public class MomentsAPISettingsBuilder: ModuleSettingsBuilder {
    typealias Keys = MomentsAPIConfiguration.Keys

    /**
     * Sets the region for the Moments API.
     *
     * - Parameter region: The Moments API region
     * - Returns: The builder instance for method chaining
     */
    public func setRegion(_ region: MomentsAPIRegion) -> Self {
        _configurationObject.set(converting: region, key: Keys.region)
        return self
    }

    /**
     * Sets the referrer for the Moments API requests.
     *
     * - Parameter referrer: The referrer URL
     * - Returns: The builder instance for method chaining
     */
    public func setReferrer(_ referrer: String) -> Self {
        _configurationObject.set(referrer, key: Keys.referrer)
        return self
    }
}
