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
    private let dataLayer: any DataStore
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
        self.dataLayer = dataLayer
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
     * The identity present in the data layer at the time of the call, if any, takes ownership of the
     * new id and its stored association is updated. If no identity is present, the new id is unowned.
     *
     * - returns: The new anonymous visitor id.
     */
    func regenerate() throws -> String {
        logger?.debug(category: LogCategory.visitorId, "Regenerating current visitor id.")
        let newId = Self.generateVisitorId()
        defer { _visitorId.onNext(newId) }
        try visitorStorage.changeVisitor(newId, withIdentity: identityInDataLayer())
        return newId
    }

    /**
     * Erases all stored identity associations, as hashed identities and their visitor ids, and generates a new
     * anonymous visitor id.
     *
     * If an identity is present in the data layer at the time of the call, it is immediately re-associated
     * with the new visitor id, so one new association may exist afterwards.
     *
     * - returns: The new anonymous visitor id.
     */
    func eraseLocalHistory() throws -> String {
        logger?.debug(category: LogCategory.visitorId, "Erasing stored identity associations.")
        let newId = Self.generateVisitorId()
        defer { _visitorId.onNext(newId) }
        try visitorStorage.eraseIdentities(settingNewVisitorId: newId, withIdentity: identityInDataLayer())
        return newId
    }

    /**
     * Reads the identity currently present in the data layer at the configured key.
     *
     * Read at call time rather than cached from data layer events, as no event is published when
     * a value expires until it is actually deleted.
     *
     * - returns: The SHA-256 of the identity present in the data layer, or `nil` if none is present.
     */
    private func identityInDataLayer() -> String? {
        guard let key = visitorIdentityKey.value,
              let identity: String = dataLayer.get(key: key),
              !identity.isBlank else {
            return nil
        }
        return identity.sha256()
    }

    /**
     * Notifies that an identity has been written to the data layer.
     *
     * A blank `identity` is ignored. So is the identity that already owns the current visitor id, as its
     * association is then already up to date.
     *
     * Otherwise, when no identity currently owns the visitor id, then this `identity` should be associated
     * with the current visitor id.
     *
     * When the `identity` has been seen before, then the visitor id should be updated to the
     * one previously associated with this `identity`.
     *
     * - Parameters:
     *   - identity: The identity written at the configured key.
     */
    func identify(identity: String) {
        guard !identity.isBlank,
              let hashedIdentity = identity.sha256(),
              hashedIdentity != visitorStorage.ownerIdentity else {
            return
        }

        logger?.debug(category: LogCategory.visitorId, "Identity change has been detected.")

        // check for known matching visitor id
        let knownVisitorId = visitorStorage.getKnownVisitorId(identity: hashedIdentity)
        if let knownVisitorId {
            // Writes the full association even when `knownVisitorId` already matches the current visitor id.
            // That case is reached after `changeVisitor` throws: this method updates `visitorId` in memory
            // before the write is confirmed, so a retry of the same identity sees `knownVisitorId == visitorId.value`.
            // If that retry wrote only the owner, a persistently failing store would leave `visitor_id` wrong
            // forever, since nothing else revisits this identity to retry the full write.
            handleExistingIdentity(knownVisitorId: knownVisitorId, identity: hashedIdentity)
        } else if visitorStorage.ownerIdentity == nil {
            handleFirstIdentity(identity: hashedIdentity)
        } else {
            handleNewIdentity(identity: hashedIdentity)
        }
    }

    private func handleExistingIdentity(knownVisitorId: String, identity: String) {
        if knownVisitorId == visitorId.value {
            logger?.debug(category: LogCategory.visitorId,
                          "Identity has been seen before and already uses the current visitor id; storing it as owner.")
        } else {
            logger?.debug(category: LogCategory.visitorId,
                          "Identity has been seen before; setting known visitor id.")
        }
        changeVisitor(knownVisitorId, withIdentity: identity)
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
            try visitorStorage.changeVisitor(visitorId, withIdentity: identity)
        } catch {
            logger?.error(category: LogCategory.visitorId,
                          "Failed to change visitor.\nError: \(error)")
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
