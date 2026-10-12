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
     * Sets the [`VisitorStorage.visitorId`](doc:VisitorStorage/visitorId) to the provided `visitorId`.
     *
     * With a non-`nil` `identity`, also sets the [`VisitorStorage.ownerIdentity`](doc:VisitorStorage/ownerIdentity)
     * to `identity` and stores an entry associating `identity` to `visitorId`, such that `visitorId`
     * can later be retrieved using `getKnownVisitorId` providing the same `identity`.
     *
     * With a `nil` `identity`, removes the `ownerIdentity` so the new `visitorId` is unowned; any
     * existing `identity.*` association rows are left untouched.
     *
     * - Parameters:
     *   - visitorId: The visitor id to store as the current visitor id.
     *   - identity: The identity to store as the owner identity, and to associate with the `visitorId`, or `nil` to leave the new `visitorId` unowned.
     */
    func changeVisitor(_ visitorId: String, withIdentity identity: String?) throws {
        let editor = storage.edit().setVisitorId(visitorId)
        guard let identity else {
            try editor.removeOwnerIdentity().commit()
            return
        }
        try editor.setOwnerIdentity(identity)
            .associateVisitor(visitorId, withIdentity: identity)
            .commit()
    }

    /**
     * Retrieves a previously seen visitor id that is associated with the given `identity`.
     */
    func getKnownVisitorId(identity: String) -> String? {
        storage.get(key: Keys.identity(identity))
    }

    /**
     * Erases every stored identity association and the `ownerIdentity`, replaces the `visitorId` with the
     * `newVisitorId`, then (with a non-`nil` `identity`) sets the `ownerIdentity` to `identity` and
     * associates `identity` with the `newVisitorId`.
     *
     * Any other entry of the underlying storage is left untouched. Applied as a single commit.
     *
     * - Parameters:
     *   - newVisitorId: the replacement visitor to save after erasing.
     *   - identity: the identity to re-associate with `newVisitorId`, or `nil` to leave it unowned.
     */
    func eraseIdentities(settingNewVisitorId newVisitorId: String, withIdentity identity: String?) throws {
        let survivingIdentityKey = identity.map(Keys.identity)
        let identityKeysToRemove = storage.keys().filter {
            $0.hasPrefix(Keys.identityPrefix) && $0 != survivingIdentityKey
        }
        let keysToRemove = identity == nil ? identityKeysToRemove + [Keys.ownerIdentity] : identityKeysToRemove
        let editor = storage.edit()
            .remove(keys: keysToRemove)
            .setVisitorId(newVisitorId)
        guard let identity else {
            try editor.commit()
            return
        }
        try editor.setOwnerIdentity(identity)
            .associateVisitor(newVisitorId, withIdentity: identity)
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

    func removeOwnerIdentity() -> Self {
        remove(key: VisitorStorage.Keys.ownerIdentity)
    }

    func associateVisitor(_ visitorId: String, withIdentity identity: String?) -> Self {
        guard let identity else {
            return self
        }
        return put(key: VisitorStorage.Keys.identity(identity), value: visitorId, expiry: .forever)
    }
}
