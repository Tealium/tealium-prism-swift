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
    /// Registrar for registering/unregistering additional barriers that control dispatch flow.
    public let barrierRegistrar: BarrierRegistrar
    /// Registrar for registering/unregistering additional data transformations.
    public let transformerRegistrar: TransformerRegistrar
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
    /// The default implementation automatically emits error-level log messages as error events
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
    /// Storage for the visitor ID: read, reset, clear, and observe.
    ///
    /// - Note: Exposed here (like `dataLayer`) so any `Module`, including this SDK's `VisitorIdProviderModule`,
    /// can reach it without going through `TealiumImpl`. As with `dataLayer`, this means any custom `Module`
    /// built on top of this context can also reset or clear the visitor ID, not just observe it.
    public let visitorIdStorage: VisitorIdStorage
    /// Metrics for queue status monitoring.
    public let queueMetrics: QueueMetrics
    /// Monitor for connectivity.
    public let connectivityManager: ConnectivityManagerProtocol
    /// The `DataStore` for the `DataLayer`
    public let dataLayer: any DataStore

    init(modulesManager: ModulesManager,
         sessionRegistry: SessionRegistry,
         config: TealiumConfig,
         coreSettings: ObservableState<CoreSettings>,
         tracker: Tracker,
         barrierRegistrar: BarrierRegistrar,
         transformerRegistrar: TransformerRegistrar,
         databaseProvider: DatabaseProviderProtocol,
         moduleStoreProvider: ModuleStoreProvider,
         logger: LoggerProtocol?,
         networkHelper: NetworkHelperProtocol,
         activityListener: ApplicationStatusListener,
         queue: TealiumQueue,
         visitorIdStorage: VisitorIdStorage,
         queueMetrics: QueueMetrics,
         connectivityManager: ConnectivityManagerProtocol,
         dataLayer: any DataStore) {
        self.modulesManager = modulesManager
        self.sessionRegistry = sessionRegistry
        self.config = config
        self.barrierRegistrar = barrierRegistrar
        self.transformerRegistrar = transformerRegistrar
        self.coreSettings = coreSettings
        self.tracker = tracker
        self.databaseProvider = databaseProvider
        self.moduleStoreProvider = moduleStoreProvider
        self.logger = logger
        self.networkHelper = networkHelper
        self.activityListener = activityListener
        self.queue = queue
        self.visitorIdStorage = visitorIdStorage
        self.queueMetrics = queueMetrics
        self.connectivityManager = connectivityManager
        self.dataLayer = dataLayer
    }
}
