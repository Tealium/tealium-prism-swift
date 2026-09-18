//
//  ContextAPISettingsBuilder.swift
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
 * Builder for Context API module settings.
 */
public class ContextAPISettingsBuilder: ModuleSettingsBuilder {
    typealias Keys = ContextAPIConfiguration.Keys

    /**
     * Sets the region for the Context API.
     *
     * - Parameter region: The Context API region
     * - Returns: The builder instance for method chaining
     */
    public func setRegion(_ region: ContextAPIRegion) -> Self {
        _configurationObject.set(converting: region, key: Keys.region)
        return self
    }

    /**
     * Sets the referrer for the Context API requests.
     *
     * - Parameter referrer: The referrer URL
     * - Returns: The builder instance for method chaining
     */
    public func setReferrer(_ referrer: String) -> Self {
        _configurationObject.set(referrer, key: Keys.referrer)
        return self
    }
}
