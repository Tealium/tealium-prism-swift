//
//  ModulesRepository.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The first dictionary key will contain the relevant module id and the second dictionary will contain the expired key-value pairs.
typealias ExpiredDataEvent = [Int64: [String: DataItem]]

/// A repository class for registering and managing modules.
protocol ModulesRepository {
    /// Observable to notify of data expiration.
    var onDataExpired: Observable<ExpiredDataEvent> { get}

    /// Returns the current existing of module names mapped to their id.
    func getModules() -> [String: Int64]

    /**
     * Registers a new module, returning the id to use for all data storage requests.
     *
     * - parameter name: the unique name of the module
     *
     * - returns: the existing id of the module if already registered, or the new id generated
     */
    func registerModule(name: String) throws -> Int64

    /**
     * Removes all data stored that is currently expired, that is, data that was expected to expire
     * at a future time; or data that matches the provided `ExpirationRequest`
     *
     * Removals are notified via onDataExpired.
     */
    func deleteExpired(expiry: ExpirationRequest)
}
