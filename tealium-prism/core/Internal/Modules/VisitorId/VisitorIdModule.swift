//
//  VisitorIdModule.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The module that owns the visitor ID: it creates and persists it, adds it to every event,
 * and switches it automatically when the identity stored in the data layer changes (Visitor Switching).
 */
class VisitorIdModule: BasicModule, Collector, VisitorIdProvider {
    static let moduleType: String = Modules.Types.visitorId
    var id: String { Self.moduleType }
    let version: String = TealiumConstants.libraryVersion

    private let visitorStorage: VisitorStorage
    private let logger: LoggerProtocol?
    private let disposables: CompositeDisposable = Disposables.automatic()

    /**
     * Observable State of the current visitor id.
     */
    @StateSubject var visitorId: ObservableState<String>

    /**
     * Observable State of the data layer key holding the identity of the user, if configured.
     */
    @StateSubject private var visitorIdentityKey: ObservableState<String?>

    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        let visitorDataStore: any DataStore
        do {
            visitorDataStore = try context.moduleStoreProvider.getModuleStore(name: Self.moduleType)
        } catch {
            context.logger?.error(category: LogCategory.visitorId,
                                  "Visitor ID module cannot be created: failed to open its storage\nError: \(error)")
            return nil
        }
        self.init(visitorStorage: VisitorStorage(storage: visitorDataStore),
                  existingVisitorId: context.config.existingVisitorId,
                  dataLayer: context.dataLayer,
                  configuration: VisitorIdConfiguration(configuration: moduleConfiguration),
                  logger: context.logger)
    }

    init(visitorStorage: VisitorStorage,
         existingVisitorId: String?,
         dataLayer: any DataStore,
         configuration: VisitorIdConfiguration,
         logger: LoggerProtocol?) {
        self.visitorStorage = visitorStorage
        self.logger = logger
        let visitorId = Self.getOrCreateVisitorId(visitorStorage: visitorStorage,
                                                  existingVisitorId: existingVisitorId)
        _visitorId = StateSubject(visitorId)
        _visitorIdentityKey = StateSubject(configuration.visitorIdentityKey)
        if visitorStorage.visitorId != visitorId {
            changeVisitor(visitorId)
        }
        VisitorSwitcher.handleIdentitySwitches(onIdentityKey: self.visitorIdentityKey,
                                               dataLayerStore: dataLayer) { [weak self] identity in
            self?.identify(identity: identity)
        }.addTo(disposables)
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        [TealiumDataKey.visitorId: visitorId.value]
    }

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        _visitorIdentityKey.onNextIfChanged(VisitorIdConfiguration(configuration: configuration).visitorIdentityKey)
        return self
    }

    func shutdown() {
        disposables.dispose()
    }

    /**
     * Regenerates the current visitor id as a new anonymous one.
     *
     * Note. the new anonymous id will be associated to the identity that owns the current visitor id, if any.
     *
     * - returns: The new anonymous visitor id.
     */
    func regenerate() throws -> String {
        logger?.debug(category: LogCategory.visitorId, "Regenerating current visitor id.")
        let newId = Self.generateVisitorId()
        defer { _visitorId.onNext(newId) }
        try visitorStorage.changeVisitor(newId)
        return newId
    }

    /**
     * Erases all stored identity associations, as hashed identities and their visitor ids, and generates a new
     * anonymous visitor id.
     *
     * - returns: The new anonymous visitor id.
     */
    func eraseLocalHistory() throws -> String {
        logger?.debug(category: LogCategory.visitorId, "Erasing stored identity associations.")
        let newId = Self.generateVisitorId()
        defer { _visitorId.onNext(newId) }
        try visitorStorage.eraseIdentities(settingNewVisitorId: newId)
        return newId
    }

    /**
     * Notifies that the identity has changed.
     *
     * When no identity currently owns the visitor id, then this `identity` should be associated with the current
     * visitor id.
     *
     * When the `identity` has been seen before, then the visitor id should be updated to the
     * one previously associated with this `identity`.
     *
     * - Parameters:
     *   - identity: The new identity of the user.
     */
    func identify(identity: String) {
        let oldIdentity = visitorStorage.ownerIdentity
        guard !identity.isBlank,
              let hashedNewIdentity = identity.sha256(),
              hashedNewIdentity != oldIdentity else {
            return
        }

        logger?.debug(category: LogCategory.visitorId, "Identity change has been detected.")

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
        logger?.debug(category: LogCategory.visitorId,
                      "Identity has been seen before; setting known visitor id.")
        changeVisitor(knownVisitorId, withIdentity: identity)
    }

    private func handleChangedIdentity(identity: String) {
        logger?.debug(category: LogCategory.visitorId,
                      "Identity has been seen before; but visitor id has not changed.")
        do {
            try visitorStorage.changeIdentity(identity: identity)
        } catch {
            logger?.error(category: LogCategory.visitorId,
                          "Failed to change identity to \(identity)\nError: \(error)")
        }
    }

    private func handleFirstIdentity(identity: String) {
        logger?.debug(category: LogCategory.visitorId,
                      "Identity unknown; linking to current visitor id.")
        changeVisitor(visitorId.value, withIdentity: identity)
    }

    private func handleNewIdentity(identity: String) {
        logger?.debug(category: LogCategory.visitorId, "Identity unknown; resetting visitor id.")

        let newVisitorId = Self.generateVisitorId()
        changeVisitor(newVisitorId, withIdentity: identity)
    }

    private func changeVisitor(_ visitorId: String, withIdentity identity: String? = nil) {
        defer { _visitorId.onNextIfChanged(visitorId) }
        do {
            if let identity {
                try visitorStorage.changeVisitor(visitorId, withIdentity: identity)
            } else {
                try visitorStorage.changeVisitor(visitorId)
            }
        } catch {
            logger?.error(category: LogCategory.visitorId,
                          "Failed to change visitor to \(visitorId)\(identity.map { " and identity " + $0 } ?? "")\nError: \(error)")
        }
    }

    /**
     * Returns a new or existing visitor ID.
     *
     * It will follow this order of preference:
     *  1. The existing visitor ID from visitor storage.
     *  2. The user configured [`TealiumConfig.existingVisitorId`](doc:TealiumConfig/existingVisitorId) if it's neither empty nor blank;
     *  Only relevant on first launch when there isn't any stored visitor ID yet.
     *  3. A brand new anonymous visitor ID.
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

    private static func generateVisitorId() -> String {
        return StringUtils.generateUUID().replacingOccurrences(of: "-", with: "")
    }
}
