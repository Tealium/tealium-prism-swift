//
//  Barriers.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Utility object for getting built-in `BarrierFactory` objects when configuring the Tealium instance.
 *
 * Some barriers are added to the system by default, but remain accessible here to allow users to
 * override the "scopes" that they apply to.
 */
public enum Barriers {

    /**
     * Returns the `BarrierFactory` for creating the "ConnectivityBarrier". Use this barrier to only
     * dispatch events when connectivity is required.
     *
     * - parameter defaultScopes: Set of `BarrierScope`s to use by default in case no other scope was
     * configured in the settings.
     */
    static func connectivity(defaultScopes: [BarrierScope] = [.dispatcher(TealiumCollect.id)]) -> any BarrierFactory {
        ConnectivityBarrier.Factory(defaultScopes: defaultScopes)
    }
}
