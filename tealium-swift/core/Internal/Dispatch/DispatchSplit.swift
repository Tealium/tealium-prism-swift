//
//  DispatchSplit.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 27/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * A split from an array of `Dispatch`es between `successful` and `unsuccessful` ones after evaluating
 * a condition on them or trying to apply some operation.
 */
typealias DispatchSplit = (successful: [Dispatch], unsuccessful: [Dispatch])
