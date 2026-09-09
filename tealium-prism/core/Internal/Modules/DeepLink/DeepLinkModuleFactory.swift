//
//  DeepLinkModuleFactory.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Creates the `DeepLinkModule`, deciding where its deep links come from.
 *
 * The module is not a `BasicModule`: on iOS its deep links come from the swizzled app delegate, and
 * a test needs a module created **by a settings pass**, as in production, to be fed a link of its
 * own. Resolving the source here keeps that platform decision out of the module.
 */
class DeepLinkModuleFactory: ModuleFactory {
    let moduleType = Modules.Types.deepLink
    let allowsMultipleInstances = false
    private let enforcedSettings: [DataObject]
    private let onOpenUrl: Observable<(URL, Referrer?)>?

    /// Creates the factory that takes its deep links from the delegate proxy, which only exists on iOS.
    convenience init(enforcedSettings: DataObject?) {
        var onOpenUrl: Observable<(URL, Referrer?)>?
        #if os(iOS)
        onOpenUrl = TealiumDelegateProxy.onOpenUrl
        #endif
        self.init(enforcedSettings: enforcedSettings, onOpenUrl: onOpenUrl)
    }

    /// Creates the factory with an explicit source of deep links, letting a test drive them.
    init(enforcedSettings: DataObject?, onOpenUrl: Observable<(URL, Referrer?)>?) {
        self.enforcedSettings = [enforcedSettings].compactMap { $0 }
        self.onOpenUrl = onOpenUrl
    }

    func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> DeepLinkModule? {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: moduleType) else {
            return nil
        }
        return DeepLinkModule(dataStore: dataStore,
                              tracker: context.tracker,
                              moduleManager: context.moduleManager,
                              configuration: DeepLinkModuleConfiguration(configuration: moduleConfiguration),
                              onOpenUrl: onOpenUrl,
                              logger: context.logger)
    }

    func getEnforcedSettings() -> [DataObject] {
        enforcedSettings
    }
}
