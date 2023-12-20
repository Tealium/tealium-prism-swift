//
//  TealiumContext.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumContext {
    public let config: TealiumConfig
    public var coreSettings: TealiumObservableState<CoreSettings>
    public let tracker: Tracker
    public let databaseProvider: DatabaseProviderProtocol
    public let moduleStoreProvider: ModuleStoreProvider
    public var modulesManager: ModulesManager
    public let logger: TealiumLoggerProvider?
    public let networkHelper: NetworkHelperProtocol
    private var automaticDisposer = TealiumAutomaticDisposer()

    init(modulesManager: ModulesManager,
         config: TealiumConfig,
         coreSettings: TealiumObservableState<CoreSettings>,
         tracker: Tracker,
         databaseProvider: DatabaseProviderProtocol,
         moduleStoreProvider: ModuleStoreProvider,
         logger: TealiumLoggerProvider?,
         networkHelper: NetworkHelperProtocol) {
        self.modulesManager = modulesManager
        self.config = config
        self.coreSettings = coreSettings
        self.tracker = tracker
        self.databaseProvider = databaseProvider
        self.moduleStoreProvider = moduleStoreProvider
        self.logger = logger
        self.networkHelper = networkHelper
    }
}
