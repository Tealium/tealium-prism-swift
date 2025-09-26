//
//  DeepLinkModule.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

class DeepLinkModule: BasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    let dataStore: DataStore
    private let tracker: Tracker
    private let modulesManager: ModulesManager
    private var configuration: DeepLinkModuleConfiguration
    private let onOpenUrl: Observable<(URL, Referrer?)>?
    private let disposer = AutomaticDisposer()
    private let logger: LoggerProtocol?
    static let moduleType: String = Modules.Types.deepLink
    var id: String { Self.moduleType }

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: Self.moduleType) else {
            return nil
        }
        var onOpenUrl: Observable<(URL, Referrer?)>?
        #if os(iOS)
        onOpenUrl = TealiumDelegateProxy.onOpenUrl
        #endif
        self.init(dataStore: dataStore,
                  tracker: context.tracker,
                  modulesManager: context.modulesManager,
                  configuration: DeepLinkModuleConfiguration(configuration: moduleConfiguration),
                  onOpenUrl: onOpenUrl,
                  logger: context.logger)
    }

    init(dataStore: DataStore,
         tracker: Tracker,
         modulesManager: ModulesManager,
         configuration: DeepLinkModuleConfiguration,
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

    func getTrace() throws -> TraceModule {
        guard let trace: TraceModule = modulesManager.getModule() else {
            throw TealiumError.moduleNotEnabled(TraceModule.self)
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
                self.logger?.error(category: id, "Failed to handle deep link \(url.absoluteString)\nError: \(error)")
            }
        }.addTo(disposer)
    }

    func handle(link: URL, referrer: Referrer? = nil) throws {
        let queryItems = URLComponents(string: link.absoluteString)?.queryItems

        if configuration.deepLinkTraceEnabled {
            try handleTrace(queryItems: queryItems)
        }
        let dataToAdd = buildDeepLinkDataObject(link: link,
                                                referrer: referrer,
                                                queryItems: queryItems)
        // clear the previously retained data (actual removal will happen on commit below)
        try dataStore.edit()
            .clear()
            .putAll(dataObject: dataToAdd, expiry: .session)
            .commit()
        if configuration.sendDeepLinkEvent {
            tracker.track(Dispatch(name: TealiumKey.deepLink, data: dataStore.getAll()),
                          source: .module(DeepLinkModule.self)) { [weak self] result in
                guard let self else { return }
                switch result.status {
                case .accepted:
                    logger?.trace(category: id, "DeepLink event accepted for dispatch.")
                case .dropped:
                    logger?.warn(category: id, "Failed to send DeepLink event: dispatch was dropped.")
                }
            }
        }
    }

    private func buildDeepLinkDataObject(link: URL, referrer: Referrer?, queryItems: [URLQueryItem]?) -> DataObject {
        var dataObject: DataObject = [
            TealiumDataKey.deepLinkURL: link.absoluteString
        ]
        switch referrer {
        case .url(let url):
            dataObject.set(url.absoluteString,
                           key: TealiumDataKey.deepLinkReferrerUrl)
        case .app(let identifier):
            dataObject.set(identifier,
                           key: TealiumDataKey.deepLinkReferrerApp)
        default:
            break
        }
        queryItems?.forEach {
            guard let value = $0.value else {
                return
            }
            dataObject.set(value,
                           key: "\(TealiumDataKey.deepLinkQueryPrefix)_\($0.name)")
        }
        return dataObject
    }

    private func handleTrace(queryItems: [URLQueryItem]?) throws {
       guard let queryItems = queryItems,
             let traceId = self.extractTraceId(from: queryItems) else {
           return
       }
        let trace = try getTrace()
        // Kill visitor session to trigger session end events
        // Session can be killed without needing to leave the trace
        if queryItems.contains(where: { $0.name == TealiumKey.killVisitorSession }) {
            try trace.killVisitorSession { [weak self] result in
                guard let self else { return }
                switch result.status {
                case .accepted:
                    logger?.trace(category: id, "Kill Visitor Session event accepted for dispatch.")
                case .dropped:
                    logger?.warn(category: id, "Failed to kill visitor session: dispatch was dropped.")
                }
            }
        }
        // Leave the trace if there is a leave param, if not - join with traceId
        if queryItems.contains(where: { $0.name == TealiumKey.leaveTraceQueryParam }) {
            try trace.leave()
        } else {
            try trace.join(id: traceId)
        }
    }

    fileprivate func extractTraceId(from queryItems: [URLQueryItem]) -> String? {
        queryItems.first {
            $0.name == TealiumKey.traceIdQueryParam && $0.value != nil
        }?.value
    }

    // MARK: Collector
    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        guard dispatchContext.source.moduleType != DeepLinkModule.self else {
            return DataObject()
        }
        return dataStore.getAll()
    }

    // MARK: Module
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        self.configuration = DeepLinkModuleConfiguration(configuration: configuration)
        return self
    }
}
