//
//  DeepLinkHandlerModule.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class DeepLinkHandlerModule: TealiumBasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "DeepLink"

    let dataStore: DataStore
    private let tracker: Tracker
    private let modulesManager: ModulesManager
    private var configuration: DeepLinkHandlerConfiguration
    private let onOpenUrl: Observable<(URL, Referrer?)>?
    private let disposer = AutomaticDisposer()
    private let logger: LoggerProtocol?

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: Self.id) else {
            return nil
        }
        var onOpenUrl: Observable<(URL, Referrer?)>?
        #if os(iOS)
        onOpenUrl = TealiumDelegateProxy.onOpenUrl
        #endif
        self.init(dataStore: dataStore,
                  tracker: context.tracker,
                  modulesManager: context.modulesManager,
                  configuration: DeepLinkHandlerConfiguration(configuration: moduleConfiguration),
                  onOpenUrl: onOpenUrl,
                  logger: context.logger)
    }

    init(dataStore: DataStore,
         tracker: Tracker,
         modulesManager: ModulesManager,
         configuration: DeepLinkHandlerConfiguration,
         onOpenUrl: Observable<(URL, Referrer?)>? = nil,
         logger: LoggerProtocol? = nil) {
        self.dataStore = dataStore
        self.tracker = tracker
        self.modulesManager = modulesManager
        self.configuration = configuration
        self.onOpenUrl = onOpenUrl
        self.logger = logger
        subscribeToOpenUrl()
    }

    func getTrace() throws -> TraceManagerModule {
        guard let trace: TraceManagerModule = modulesManager.getModule() else {
            throw TealiumError.moduleNotEnabled
        }
        return trace
    }

    private func subscribeToOpenUrl() {
        self.onOpenUrl?.subscribe { [weak self] url, referrer in
            guard let self else { return }
            do {
                try self.handle(link: url, referrer: referrer)
            } catch {
                // Log the error
                self.logger?.error(category: Self.id, "Failed to handle deep link \(url.absoluteString)\nError: \(error.localizedDescription)")
            }
        }.addTo(disposer)
    }

    func handle(link: URL, referrer: Referrer? = nil) throws {
        let queryItems = URLComponents(string: link.absoluteString)?.queryItems

        if let queryItems = queryItems,
           let traceId = self.extractTraceId(from: queryItems),
           configuration.qrTraceEnabled {
            // Kill visitor session to trigger session end events
            // Session can be killed without needing to leave the trace
            if link.query?.contains(TealiumKey.killVisitorSession) == true {
                try self.killTraceVisitorSession()
            }
            // Leave the trace if there is a leave param, if not - join with traceId
            if link.query?.contains(TealiumKey.leaveTraceQueryParam) == true {
                try self.leaveTrace()
            } else {
                try self.joinTrace(id: traceId)
            }
        }
        if configuration.deepLinkTrackingEnabled {
            // clear the prevously retained data (actual removal will happen on commit below)
            let edits = dataStore.edit().clear()
            switch referrer {
            case .url(let url):
                _ = edits.put(key: TealiumDataKey.deepLinkReferrerUrl, value: url.absoluteString, expiry: .session)
            case .app(let identifier):
                _ = edits.put(key: TealiumDataKey.deepLinkReferrerApp, value: identifier, expiry: .session)
            default:
                break
            }
            queryItems?.forEach {
                guard let value = $0.value else {
                    return
                }
                _ = edits.put(key: "\(TealiumDataKey.deepLinkQueryPrefix)_\($0.name)", value: value, expiry: .session)
            }
            try edits.put(key: TealiumDataKey.deepLinkURL, value: link.absoluteString, expiry: .session)
                .commit()
            if configuration.sendDeepLinkEvent {
                tracker.track(TealiumDispatch(name: TealiumKey.deepLink, data: dataStore.getAll()), source: .module(DeepLinkHandlerModule.self))
            }
        }
    }

    fileprivate func extractTraceId(from queryItems: [URLQueryItem]) -> String? {
        queryItems.first { $0.name == TealiumKey.traceIdQueryParam && $0.value != nil }?.value
    }

    /// Sends a request to modules to initiate a trace with a specific Trace ID￼.
    ///
    /// - Parameter id: String representing the Trace ID
    func joinTrace(id: String) throws {
        try getTrace().join(id: id)
    }

    /// Sends a request to modules to leave a trace, and end the trace session￼.
    ///
    func leaveTrace() throws {
        try getTrace().leave()
    }

    /// Ends the current visitor session. Trace remains active, but visitor session is terminated.
    func killTraceVisitorSession() throws {
        try getTrace().killVisitorSession()
    }

    // MARK: Collector
    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        guard dispatchContext.source.moduleType != DeepLinkHandlerModule.self else {
            return DataObject()
        }
        return dataStore.getAll()
    }

    // MARK: TealiumModule
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        self.configuration = DeepLinkHandlerConfiguration(configuration: configuration)
        return self
    }
}
