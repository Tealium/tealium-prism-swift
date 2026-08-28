//
//  CollectModule.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `Dispatcher` that sends events to our Tealium Collect service.
 */
class CollectModule: Dispatcher {
    let version: String = TealiumConstants.libraryVersion
    let id: String
    let dispatchLimit = 10
    let batcher = CollectBatcher()
    let networkClient: NetworkClient
    let logger: LoggerProtocol?
    var configuration: CollectModuleConfiguration

    /// Generic `Dispatcher` initializer called by the `CollectModule.Factory`.
    required convenience init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(moduleId: moduleId,
                  networkClient: context.network.networkClient,
                  configuration: CollectModuleConfiguration(configuration: moduleConfiguration,
                                                            logger: context.logger),
                  logger: context.logger)
    }

    /// Internal initializer called by the generic one and by the tests.
    init?(moduleId: String = Modules.Types.collect,
          networkClient: NetworkClient,
          configuration: CollectModuleConfiguration?,
          logger: LoggerProtocol?) {
        guard let configuration else {
            return nil
        }
        self.id = moduleId
        self.networkClient = networkClient
        self.configuration = configuration
        self.logger = logger
    }

    /// Method that will be called automatically when new configuration is provided.
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        guard let collectConfiguration = CollectModuleConfiguration(configuration: configuration,
                                                                    logger: self.logger) else {
            return nil
        }
        self.configuration = collectConfiguration
        return self
    }

    /**
     * Sends a list of events to the Tealium Collect service.
     *
     * The provided events need to already be limited by the `dispatchLimit`.
     * In case of multiple events with different `visitorId`s this method will automatically group them by `visitorId` and send them separately.
     * The completion block can, therefore, be called more than once with the list of dispatches that are actually completed every time.
     */
    func dispatch(_ events: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> any Disposable {
        if events.count == 1 {
            return sendSingleDispatch(events[0], completion: completion)
        } else {
            let batches = batcher.splitDispatchesByVisitorId(events)
            logger?.trace(category: LogCategory.collect,
                          "Collect events split in batches \(batches)")
            let container = DisposableContainer()
            for batch in batches where !batch.isEmpty {
                if batch.count == 1 {
                    sendSingleDispatch(batch[0], completion: completion)
                        .addTo(container)
                } else {
                    sendBatchDispatches(batch, completion: completion)
                        .addTo(container)
                }
            }
            return container
        }
    }

    /**
     * Sends an event to the single event endpoint.
     *
     * This method will create the JSON, eventually apply the `overrideProfile`,
     * and then send the gzipped payload with a POST request to the batch endpoint.
     */
    func sendSingleDispatch(_ event: Dispatch, completion: @escaping ([Dispatch]) -> Void) -> any Disposable {
        var data = event.payload
        batcher.applyProfileOverride(configuration.overrideProfile, to: &data)
        let urlWithTrace = urlWithTraceId(baseUrl: configuration.url, dispatches: [event])
        return send(url: urlWithTrace, body: data, dispatches: [event], completion: completion)
    }

    /**
     * Sends a list of events to the batch endpoint.
     *
     * The provided events need to already be limited by the `dispatchLimit`
     * and be connected to the same `visitorId` (or eventually no `visitorId`).
     * This method will create the JSON by compressing those batches, eventually apply the `overrideProfile`,
     * and then send the payload with a gzipped POST request to the batch endpoint.
     */
    func sendBatchDispatches(_ events: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> any Disposable {
        guard let batchData = batcher.compressDispatches(events, profileOverride: configuration.overrideProfile) else {
            return Disposables.disposed()
        }
        let urlForPost = urlWithTraceId(baseUrl: configuration.batchUrl, dispatches: events)
        return send(url: urlForPost, body: batchData, dispatches: events, completion: completion)
    }

    /**
     * Sends the given JSON body as a **gzipped** POST through the `NetworkClient`, completing with the
     * `dispatches` that were sent (or an empty array if the request was cancelled).
     *
     * Compression is explicit here: unlike `NetworkHelper`, Collect opts into gzip because the Tealium
     * Collect endpoint supports it.
     */
    private func send(url: URL,
                      body: DataObject,
                      dispatches: [Dispatch],
                      completion: @escaping ([Dispatch]) -> Void) -> any Disposable {
        networkClient.sendRequest(.makePOST(url: url, json: body).gzip()) { result in
            if case .failure(let error) = result,
               case .cancelled = error.type {
                completion([])
                return
            }
            completion(dispatches)
        }
    }

    /**
     * Constructs a URL with trace ID query parameter if present in the payload.
     */
    private func urlWithTraceId(baseUrl urlFromConfig: URL, dispatches: [Dispatch]) -> URL {
        if let traceId = dispatches.lazy
            .compactMap({ $0.payload.get(key: TealiumDataKey.tealiumTraceId, as: String.self) })
            .first(where: { !$0.isEmpty }) {
            urlFromConfig.appendingQueryItems([
                URLQueryItem(name: TealiumDataKey.tealiumTraceId, value: traceId)
            ])
        } else {
            urlFromConfig
        }
    }
}
