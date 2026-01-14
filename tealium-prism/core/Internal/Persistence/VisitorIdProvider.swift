//
//  VisitorIdProvider.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

class VisitorIdProvider {
    private let visitorCategory = LogCategory.visitorIdProvider
    private let visitorStorage: VisitorStorage
    private let logger: LoggerProtocol?
    /**
     * Observable State of the current visitor id.
     */
    @StateSubject var visitorId: ObservableState<String>

    convenience init(config: TealiumConfig, visitorDataStore: any DataStore, logger: LoggerProtocol?) {
        self.init(existingVisitorId: config.existingVisitorId,
                  visitorStorage: VisitorStorage(storage: visitorDataStore),
                  logger: logger)
    }

    init(existingVisitorId: String?, visitorStorage: VisitorStorage, logger: LoggerProtocol?) {
        self.visitorStorage = visitorStorage
        self.logger = logger
        let visitorId = Self.getOrCreateVisitorId(visitorStorage: visitorStorage,
                                                  existingVisitorId: existingVisitorId)
        _visitorId = StateSubject(visitorId)
        if visitorStorage.visitorId != visitorId {
            changeVisitor(visitorId)
        }
    }

    /**
     * Resets the current visitor id to a new anonymous one.
     *
     * Note. the new anonymous id will be associated to any identity currently set.
     *
     * - returns: The new anonymous visitor id.
     */
    func resetVisitorId() throws -> String {
        logger?.debug(category: visitorCategory, "Resetting current visitor id.")
        let newId = Self.generateVisitorId()
        defer { _visitorId.publish(newId) }
        try visitorStorage.changeVisitor(newId)
        return newId
    }

    /**
     * Removes all stored visitor identifiers as hashed identities, and generates a new
     * anonymous visitor id.
     * 
     * - returns: The new anonymous visitor id.
     */
    func clearStoredVisitorIds() throws -> String {
        logger?.debug(category: visitorCategory, "Clearing stored visitor ids.")
        let newId = Self.generateVisitorId()
        defer { _visitorId.publish(newId) }
        try visitorStorage.clear(settingNewVisitorId: newId)
        return newId
    }

    /**
     * Notifies that the identity has changed.
     *
     * When no identity is currently set, then this `identity` should be associated with the current
     * visitor id.
     *
     * When the `identity` has been seen before, then the visitor id should be updated to the
     * one previously associated with this `identity`.
     *
     * - Parameters:
     *   - identity: The new identity of the user.
     */
    func identify(identity: String) {
        guard !identity.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let oldIdentity = visitorStorage.currentIdentity
        guard let hashedNewIdentity = identity.sha256(),
              hashedNewIdentity != oldIdentity else {
            return
        }

        logger?.debug(category: visitorCategory, "Identity change has been detected.")

        // check for known matching visitor id
        let knownVisitorId = visitorStorage.getKnownVisitorId(identity: hashedNewIdentity)
        if let knownVisitorId {
            if knownVisitorId != visitorId.value {
                handleExistingIdentity(knownVisitorId: knownVisitorId, identity: hashedNewIdentity)
            } else {
                handleChangedIdentity(identity: hashedNewIdentity)
            }
        } else if oldIdentity == nil {
            handleFirstIdentity(identity: hashedNewIdentity)
        } else {
            handleNewIdentity(identity: hashedNewIdentity)
        }
    }

    private func handleExistingIdentity(knownVisitorId: String, identity: String) {
        logger?.debug(category: visitorCategory,
                      "Identity has been seen before; setting known visitor id.")
        changeVisitor(knownVisitorId, withIdentity: identity)
    }

    private func handleChangedIdentity(identity: String) {
        logger?.debug(category: visitorCategory,
                      "Identity has been seen before; but visitor id has not changed.")
        do {
            try visitorStorage.changeIdentity(identity: identity)
        } catch {
            logger?.error(category: visitorCategory,
                          "Failed to change identity to \(identity)\nError: \(error)")
        }
    }

    private func handleFirstIdentity(identity: String) {
        logger?.debug(category: visitorCategory,
                      "Identity unknown; linking to current visitor id.")
        changeVisitor(visitorId.value, withIdentity: identity)
    }

    private func handleNewIdentity(identity: String) {
        logger?.debug(category: visitorCategory, "Identity unknown; resetting visitor id.")

        let newVisitorId = Self.generateVisitorId()
        changeVisitor(newVisitorId, withIdentity: identity)
    }

    private func changeVisitor(_ visitorId: String, withIdentity identity: String? = nil) {
        defer { _visitorId.publishIfChanged(visitorId) }
        do {
            if let identity {
                try visitorStorage.changeVisitor(visitorId, withIdentity: identity)
            } else {
                try visitorStorage.changeVisitor(visitorId)
            }
        } catch {
            logger?.error(category: visitorCategory,
                          "Failed to change visitor to \(visitorId)\(identity.flatMap { " and identity " + $0 } ?? "")\nError: \(error)")
        }
    }

    /**
     * Returns a new or existing visitor ID.
     *
     * It will follow this order of preference:
     *  1. The existing visitor ID from visitor storage.
     *  2. A visitor ID that is able to be migrated from a previous sdk version during an upgrade.
     *  3. The user configured `TealiumConfig.existingVisitorId` if it's neither empty nor blank; Only relevant on first launch
     *  when there isn't any stored visitor ID yet.
     *  4. A brand new anonymous visitor ID.
     */
    private static func getOrCreateVisitorId(visitorStorage: VisitorStorage, existingVisitorId: String?) -> String {
        if let storedVisitorId = visitorStorage.visitorId {
            return storedVisitorId
        }
        if let existingVisitorId, !existingVisitorId.isBlank {
            return existingVisitorId
        }
        return generateVisitorId()
    }

    private static func generateVisitorId(_ uuid: UUID = UUID()) -> String {
        return uuid.uuidString.replacingOccurrences(of: "-", with: "")
    }
}
