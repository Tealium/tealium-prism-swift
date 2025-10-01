//
//  RefreshParameters.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct RefreshParameters {
    let id: String
    let url: URL
    var refreshInterval: TimeFrame
    let errorCooldownBaseInterval: TimeFrame?

    /**
     * Creates parameters to be used with a `ResourceRefresher`.
     *
     * - Parameters:
     *   - id: A unique String, used to identify the specific Refresher and the specific Resource it's refreshing.
     *   - url: The URL used to send the GET requests
     *   - refreshInterval: the interval used to refresh the resource after the initial refresh
     *   - errorCooldownBaseInterval: if present, it's the interval that is used, instead of the `refreshInterval`, in case of no resource found in the cache. It must be lower then `refreshInterval` if provided.
     */
    public init(id: String, url: URL, refreshInterval: TimeFrame, errorCooldownBaseInterval: TimeFrame? = nil) {
        self.id = id
        self.url = url
        self.refreshInterval = refreshInterval
        self.errorCooldownBaseInterval = errorCooldownBaseInterval
    }
}
