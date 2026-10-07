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
 *
 * The rows it stores are:
 * - `visitor_id`: the current visitor id.
 * - `owner_identity`: the identity that owns the current visitor id; absent while the visitor id is not owned by any identity.
 * - `identity.<identity>`: the visitor id that the identity was last associated with.
 */
class VisitorStorage {
    enum Keys {
        static let visitorId = "visitor_id"
        static let ownerIdentity = "owner_identity"
        static let identityPrefix = "identity."

        static func identity(_ identity: String) -> String {
            identityPrefix + identity
        }
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
     * Returns the identity that owns the current visitor id, if available.
     */
    var ownerIdentity: String? {
        storage.get(key: Keys.ownerIdentity)
    }

    /**
     * Sets the [`VisitorStorage.visitorId`](doc:VisitorStorage/visitorId) to the provided `visitorId`. It does not update the `ownerIdentity`.
     *
     * Also stores an entry associating `ownerIdentity` to `visitorId` such that a previous `visitorId`
     * can be retrieved using `getKnownVisitorId` providing the same identity.
     *
     * - Parameters:
     *   - visitorId: The visitor id to store as the current visitor id.
     */
    func changeVisitor(_ visitorId: String) throws {
        try storage.edit()
            .setVisitorId(visitorId)
            .associateVisitor(visitorId, withIdentity: ownerIdentity)
            .commit()
    }

    /**
     * Sets the [`VisitorStorage.visitorId`](doc:VisitorStorage/visitorId) to the provided `visitorId` and sets the
     * [`VisitorStorage.ownerIdentity`](doc:VisitorStorage/ownerIdentity) to the provided `identity`.
     *
     * Also stores an entry associating `identity` to `visitorId` such that a previous `visitorId`
     * can be retrieved using `getKnownVisitorId` providing the same `identity`.
     *
     * - Parameters:
     *   - visitorId: The visitor id to store as the current visitor id.
     *   - identity: The identity to store as the owner identity, and to associate with the `visitorId`.
     */
    func changeVisitor(_ visitorId: String, withIdentity identity: String) throws {
        try storage.edit()
            .setVisitorId(visitorId)
            .setOwnerIdentity(identity)
            .associateVisitor(visitorId, withIdentity: identity)
            .commit()
    }

    /**
     * Sets the [`VisitorStorage.ownerIdentity`](doc:VisitorStorage/ownerIdentity) to the provided `identity`.
     *
     * It does not create any associations between the `ownerIdentity` and the `visitorId`.
     *
     * - Parameters:
     *   - identity: The identity to change to.
     */
    func changeIdentity(identity: String) throws {
        try storage.edit()
            .setOwnerIdentity(identity)
            .commit()
    }

    /**
     * Retrieves a previously seen visitor id that is associated with the given `identity`.
     */
    func getKnownVisitorId(identity: String) -> String? {
        storage.get(key: Keys.identity(identity))
    }

    /**
     * Erases every stored identity association and the `ownerIdentity`, and replaces the `visitorId` with the `newVisitorId`.
     *
     * Any other entry of the underlying storage is left untouched.
     *
     * - Parameters:
     *   - newVisitorId: the replacement visitor to save after erasing.
     */
    func eraseIdentities(settingNewVisitorId newVisitorId: String) throws {
        let identityKeys = storage.keys().filter { $0.hasPrefix(Keys.identityPrefix) }
        try storage.edit()
            .remove(keys: identityKeys + [Keys.ownerIdentity])
            .setVisitorId(newVisitorId)
            .commit()
    }
}

fileprivate extension DataStoreEditor {
    func setVisitorId(_ visitorId: String) -> Self {
        put(key: VisitorStorage.Keys.visitorId, value: visitorId, expiry: .forever)
    }

    func setOwnerIdentity(_ identity: String) -> Self {
        put(key: VisitorStorage.Keys.ownerIdentity, value: identity, expiry: .forever)
    }

    func associateVisitor(_ visitorId: String, withIdentity identity: String?) -> Self {
        guard let identity else {
            return self
        }
        return put(key: VisitorStorage.Keys.identity(identity), value: visitorId, expiry: .forever)
    }
}
