//
//  DeepLinkModule.swift
//  tealium-prism
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

class DeepLinkModule: Collector {
    let version: String = TealiumConstants.libraryVersion
    let dataStore: any DataStore
    private let tracker: Tracker
    private let moduleManager: ModuleManager
    private var configuration: DeepLinkModuleConfiguration
    private let onOpenUrl: Observable<(URL, Referrer?)>?
    private let disposer = Disposables.automatic()
    /**
     * Trace lookups still waiting for the modules to be created. Failed when this module shuts down.
     *
     * Automatic, so a module that is released without a `shutdown` still fails its pending lookups
     * instead of leaving their callers waiting forever.
     */
    private let traceSubscriptions = Disposables.automatic()
    private let logger: LoggerProtocol?
    static let moduleType: String = Modules.Types.deepLink
    var id: String { Self.moduleType }

    init(dataStore: any DataStore,
         tracker: Tracker,
         moduleManager: ModuleManager,
         configuration: DeepLinkModuleConfiguration,
         onOpenUrl: Observable<(URL, Referrer?)>? = nil,
         logger: LoggerProtocol? = nil) {
        self.dataStore = dataStore
        self.tracker = tracker
        self.moduleManager = moduleManager
        self.configuration = configuration
        self.onOpenUrl = onOpenUrl
        self.logger = logger
        subscribeToOpenUrl()
    }

    private func subscribeToOpenUrl() {
        self.onOpenUrl?.subscribe { [weak self] url, referrer in
            guard let self else { return }
            handle(link: url, referrer: referrer) { [weak self] result in
                guard let self, case .failure(let error) = result else { return }
                logger?.error(category: id, "Failed to handle deep link \(url.absoluteString)\nError: \(error)")
            }
        }.addTo(disposer)
    }

    /**
     * Handles a deep link, joining the trace it requests when there is one.
     *
     * The trace lookup is asynchronous on purpose: a deep link that launched the app can reach this
     * module before the modules of the first settings pass have been published, and a missing
     * `TraceModule` at that point means "not created yet", not "disabled".
     *
     * - Parameters:
     *   - link: The deep link to handle.
     *   - referrer: Where the deep link came from, when known.
     *   - completion: Called exactly once, when the deep link has been handled or with the failure
     *   that stopped it. A shutdown while the trace lookup is pending is such a failure.
     */
    func handle(link: URL,
                referrer: Referrer? = nil,
                completion: @escaping (Result<Void, ModuleError<Error>>) -> Void = { _ in }) {
        let queryItems = URLComponents(string: link.absoluteString)?.queryItems
        let traceId = configuration.deepLinkTraceEnabled
            ? queryItems.flatMap { extractTraceId(from: $0) }
            : nil
        guard let traceId, let queryItems else {
            completion(Self.wrappingErrors { try handleDeepLink(link: link, referrer: referrer, queryItems: queryItems) })
            return
        }
        onTraceModule { [weak self] traceResult in
            completion(Self.wrappingErrors {
                // Released without a shutdown: there is no module left to handle the link with.
                guard let self else { throw ModuleError<Error>.moduleShutdown("\(DeepLinkModule.self)") }
                // Join first: the deep link event has to land inside the trace.
                try self.applyTrace(traceResult.get(), traceId: traceId, queryItems: queryItems)
                try self.handleDeepLink(link: link, referrer: referrer, queryItems: queryItems)
            })
        }
    }

    /**
     * Runs the block, reporting whatever it throws as a `ModuleError`.
     *
     * `Result.init(catching:)` can only build a `Result<_, any Error>`, so the wrapping that
     * `ModuleError` already knows how to do is applied explicitly here.
     */
    private static func wrappingErrors(_ block: () throws -> Void) -> Result<Void, ModuleError<Error>> {
        do {
            try ModuleError<Error>.wrapErrors(block: block)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    /**
     * Resolves the `TraceModule`, waiting for it when the modules haven't been created yet.
     *
     * Fails with `ModuleError.moduleNotEnabled` when Trace is not enabled, or with
     * `ModuleError.moduleShutdown` when this module is shut down while the lookup is pending.
     */
    private func onTraceModule(_ completion: @escaping (Result<TraceModule, ModuleError<Error>>) -> Void) {
        let pending = Disposables.composite()
        // Disposed by shutdown, which fails the lookups that are never going to resolve.
        Disposables.subscription {
            completion(.failure(.moduleShutdown("\(DeepLinkModule.self)")))
        }.addTo(pending)
        traceSubscriptions.add(pending)
        // Already shut down: `add` disposed `pending`, so the guard above already failed this lookup.
        guard !pending.isDisposed else { return }
        moduleManager.observeModule(TraceModule.self)
            .subscribeOnce { [weak self] trace in
                // Drops the shutdown guard: removing does not dispose, so it can no longer fire.
                self?.traceSubscriptions.remove(pending)
                guard let trace else {
                    completion(.failure(.moduleNotEnabled("\(TraceModule.self)")))
                    return
                }
                completion(.success(trace))
            }.addTo(pending)
    }

    private func handleDeepLink(link: URL, referrer: Referrer?, queryItems: [URLQueryItem]?) throws {
        let dataToAdd = buildDeepLinkDataObject(link: link,
                                                referrer: referrer,
                                                queryItems: queryItems)
        // clear the previously retained data (actual removal will happen on commit below)
        try dataStore.edit()
            .clear()
            .putAll(dataObject: dataToAdd, expiry: .session)
            .commit()
        if configuration.sendDeepLinkEvent {
            tracker.track(Dispatch(name: TealiumConstants.deepLinkEvent, data: dataStore.getAll()),
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

    /// Applies the trace requested by the deep link. May throw - callers run this inside a `Result`.
    private func applyTrace(_ trace: TraceModule, traceId: String, queryItems: [URLQueryItem]) throws {
        // Force end of visit to trigger session end events
        // Session can be forced to end without needing to leave the trace
        if queryItems.contains(where: { $0.name == TealiumConstants.forceEndOfVisitQueryParam }) {
            try trace.forceEndOfVisit { [weak self] result in
                guard let self else { return }
                switch result.status {
                case .accepted:
                    logger?.trace(category: id, "Force end of visit event accepted for dispatch.")
                case .dropped:
                    logger?.warn(category: id, "Failed to force end of visit: dispatch was dropped.")
                }
            }
        }
        // Leave the trace if there is a leave param, if not - join with traceId
        if queryItems.contains(where: { $0.name == TealiumConstants.leaveTraceQueryParam }) {
            try trace.leave()
        } else {
            try trace.join(id: traceId)
        }
    }

    fileprivate func extractTraceId(from queryItems: [URLQueryItem]) -> String? {
        queryItems.first {
            $0.name == TealiumDataKey.tealiumTraceId && $0.value != nil
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

    func shutdown() {
        // Fails the trace lookups that are still waiting, instead of leaving their callers hanging.
        traceSubscriptions.dispose()
        disposer.dispose()
    }
}
