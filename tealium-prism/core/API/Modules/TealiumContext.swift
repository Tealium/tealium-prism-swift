//
//  TealiumContext.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Provides context and dependencies for modules within the Tealium SDK.
public class TealiumContext {
    /// The configuration used to initialize Tealium.
    public let config: TealiumConfig
    /// Observable core settings that can be updated at runtime.
    public let coreSettings: ObservableState<CoreSettings>
    /// The tracker responsible for processing and dispatching events.
    public let tracker: Tracker
    /// Registry for managing barriers that control dispatch flow.
    public let barrierRegistry: BarrierRegistry
    /// Registry for managing data transformers.
    public let transformerRegistry: TransformerRegistry
    /// Provider for database connections.
    public let databaseProvider: DatabaseProviderProtocol
    /// Provider for module-specific data stores.
    public let moduleStoreProvider: ModuleStoreProvider
    /// Manager for module lifecycle and configuration.
    public let modulesManager: ModulesManager
    /// Registry for session management.
    public let sessionRegistry: SessionRegistry
    /// Logger for SDK messages, if configured.
    /// 
    /// The default implementation automatically publishes error-level log messages as error events
    /// that can be tracked by `Trace` (if error tracking is enabled) during trace sessions.
    /// To prevent infinite loops of error events, always use a limited set of non-dynamic categories when logging.
    /// Categories should be static strings that identify the component (e.g., "NetworkModule", "TraceModule")
    /// rather than dynamic values like user data or timestamps.
    public let logger: LoggerProtocol?
    /// Helper for network operations.
    public let networkHelper: NetworkHelperProtocol
    /// Listener for application lifecycle events.
    public let activityListener: ApplicationStatusListener
    /// Queue for SDK operations.
    public let queue: TealiumQueue
    /// Observable visitor ID.
    public let visitorId: ObservableState<String>
    /// Metrics for queue status monitoring.
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
