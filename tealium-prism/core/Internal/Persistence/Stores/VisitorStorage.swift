//
//  VisitorStorage.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * `VisitorStorage` provides a set of methods to store, retrieve and associate visitors to known
 * identities.
 *
 * Identities provided to these methods should be consistent and should be hashed to avoid storing
 * personal data unnecessarily.
 */
class VisitorStorage {
    enum Keys {
        static let visitorId = "visitorId"
        static let currentIdentity = "currentIdentity"
    }
    private let storage: any DataStore
    init(storage: any DataStore) {
        self.storage = storage
    }

    /**
     * Returns the currently stored visitor id if available.
     *
     * This getter should only return `nil` on first creation/launch.
     */
    var visitorId: String? {
        storage.get(key: Keys.visitorId)
    }

    /**
     * Returns the currently stored identity if available.
     */
    var currentIdentity: String? {
        storage.get(key: Keys.currentIdentity)
    }

    /**
     * Sets the `VisitorStorage.visitorId` to the provided `visitorId`. It does not update the `currentIdentity`.
     *
     * Also stores an entry associating `currentIdentity` to `visitorId` such that a previous `visitorId`
     * can be retrieved using `getKnownVisitorId` providing the same identity.
     *
     * - Parameters:
     *   - visitorId: The visitor id to store as the current visitor id.
     */
    func changeVisitor(_ visitorId: String) throws {
        try storage.edit()
            .setVisitorId(visitorId)
            .associateVisitor(visitorId, withIdentity: currentIdentity)
            .commit()
    }

    /**
     * Sets the `VisitorStorage.visitorId` to the provided `visitorId` and sets the
     * `VisitorStorage.currentIdentity` to the provided `identity`.
     *
     * Also stores an entry associating `identity` to `visitorId` such that a previous `visitorId`
     * can be retrieved using `getKnownVisitorId` providing the same `identity`.
     *
     * - Parameters:
     *   - visitorId: The visitor id to store as the current visitor id.
     *   - identity: The identity to store as the current identity, and to associate with the `visitorId`.
     */
    func changeVisitor(_ visitorId: String, withIdentity identity: String) throws {
        try storage.edit()
            .setVisitorId(visitorId)
            .setCurrentIdentity(identity)
            .associateVisitor(visitorId, withIdentity: identity)
            .commit()
    }

    /**
     * Sets the `VisitorStorage.currentIdentity` to the provided `identity`.
     *
     * It does not create any associations between the `currentIdentity` and the `visitorId`.
     *
     * - Parameters:
     *   - identity: The identity to change to.
     */
    func changeIdentity(identity: String) throws {
        try storage.edit()
            .setCurrentIdentity(identity)
            .commit()
    }

    /**
     * Retrieves a previously seen visitor id that is associated with the given `identity`.
     */
    func getKnownVisitorId(identity: String) -> String? {
        storage.get(key: identity)
    }

    /**
     * Clears all stored VisitorId's and identities, and replaces the `visitorId` with the `newVisitorId`
     *
     * - Parameters:
     *   - newVisitorId: the replacement visitor to save after clearing.
     */
    func clear(settingNewVisitorId newVisitorId: String) throws {
        try storage.edit()
            .clear()
            .setVisitorId(newVisitorId)
            .commit()
    }
}

fileprivate extension DataStoreEditor {
    func setVisitorId(_ visitorId: String) -> Self {
        put(key: VisitorStorage.Keys.visitorId, value: visitorId, expiry: .forever)
    }

    func setCurrentIdentity(_ identity: String) -> Self {
        put(key: VisitorStorage.Keys.currentIdentity, value: identity, expiry: .forever)
    }

    func associateVisitor(_ visitorId: String, withIdentity identity: String?) -> Self {
        guard let identity else {
            return self
        }
        return put(key: identity, value: visitorId, expiry: .forever)
    }
}
