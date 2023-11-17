//
//  TealiumContext.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumContext {
    public weak var tealiumProtocol: TealiumProtocol?
    public let config: TealiumConfig
    public var coreSettings: CoreSettings
    public let onSettingsUpdate: TealiumObservable<CoreSettings>
    public let databaseProvider: DatabaseProvider
    public let moduleStoreProvider: ModuleStoreProvider
    public weak var modulesManager: ModulesManager?
    public let logger: TealiumLoggerProvider
    public let networkHelper: NetworkHelperProtocol
    private var automaticDisposer = TealiumAutomaticDisposer()

    init(_ teal: TealiumProtocol,
         modulesManager: ModulesManager,
         config: TealiumConfig,
         coreSettings: CoreSettings,
         onSettingsUpdate: TealiumObservable<CoreSettings>,
         databaseProvider: DatabaseProvider,
         moduleStoreProvider: ModuleStoreProvider,
         logger: TealiumLoggerProvider,
         networkHelper: NetworkHelperProtocol) {
        self.tealiumProtocol = teal
        self.modulesManager = modulesManager
        self.config = config
        self.coreSettings = coreSettings
        self.onSettingsUpdate = onSettingsUpdate
        self.databaseProvider = databaseProvider
        self.moduleStoreProvider = moduleStoreProvider
        self.logger = logger
        self.networkHelper = networkHelper
        onSettingsUpdate.subscribe { [weak self] settings in
            self?.coreSettings = settings
        }.addTo(automaticDisposer)
    }
}
