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
    public let coreSettings: ObservableState<CoreSettings>
    public let tracker: Tracker
    public let barrierRegistry: BarrierRegistry
    public let transformerRegistry: TransformerRegistry
    public let databaseProvider: DatabaseProviderProtocol
    public let moduleStoreProvider: ModuleStoreProvider
    public let modulesManager: ModulesManager
    public let sessionRegistry: SessionRegistry
    public let logger: LoggerProtocol?
    public let networkHelper: NetworkHelperProtocol
    public let activityListener: ApplicationStatusListener
    public let queue: TealiumQueue
    public let visitorId: ObservableState<String>
    public let queueMetrics: QueueMetrics

    init(modulesManager: ModulesManager,
         sessionRegistry: SessionRegistry,
         config: TealiumConfig,
         coreSettings: ObservableState<CoreSettings>,
         tracker: Tracker,
         barrierRegistry: BarrierRegistry,
         transformerRegistry: TransformerRegistry,
         databaseProvider: DatabaseProviderProtocol,
         moduleStoreProvider: ModuleStoreProvider,
         logger: LoggerProtocol?,
         networkHelper: NetworkHelperProtocol,
         activityListener: ApplicationStatusListener,
         queue: TealiumQueue,
         visitorId: ObservableState<String>,
         queueMetrics: QueueMetrics) {
        self.modulesManager = modulesManager
        self.sessionRegistry = sessionRegistry
        self.config = config
        self.barrierRegistry = barrierRegistry
        self.transformerRegistry = transformerRegistry
        self.coreSettings = coreSettings
        self.tracker = tracker
        self.databaseProvider = databaseProvider
        self.moduleStoreProvider = moduleStoreProvider
        self.logger = logger
        self.networkHelper = networkHelper
        self.activityListener = activityListener
        self.queue = queue
        self.visitorId = visitorId
        self.queueMetrics = queueMetrics
    }
}
