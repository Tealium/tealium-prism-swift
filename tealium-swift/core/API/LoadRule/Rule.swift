//
//  Rule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * A wrapper around some generic Item that can be composed with logical operators like AND, OR and NOT.
 *
 * This can be used to create compositions of `Condition` objects or to define the `LoadRule` IDs that have to be applied, or excluded, to a specific `Dispatcher` or `Collector`.
 */
public indirect enum Rule<Item> {
    /// Returns true if it does NOT contain any false Item.
    case and([Self])
    /// Returns true if at least one contained item is true.
    case or([Self])
    /// Negates the boolean value contained in the Item.
    case not(Self)
    /// It's just a wrapper for the item itself.
    case just(Item)
}
