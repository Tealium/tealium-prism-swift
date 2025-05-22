//
//  TealiumCollect.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `Dispatcher` that sends events to our Tealium Collect service.
 */
class TealiumCollect: TealiumBasicModule, Dispatcher {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "Collect"
    let dispatchLimit = 10
    let batcher = CollectBatcher()
    let networkHelper: NetworkHelperProtocol
    let logger: LoggerProtocol?
    var configuration: CollectConfiguration

    /// Generic `Dispatcher` initializer called by the `ModulesManager`.
    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(networkHelper: context.networkHelper,
                  configuration: CollectConfiguration(configuration: moduleConfiguration,
                                                      logger: context.logger),
                  logger: context.logger)
    }

    /// Internal initializer called by the generic one and by the tests.
    init?(networkHelper: NetworkHelperProtocol, configuration: CollectConfiguration?, logger: LoggerProtocol?) {
        guard let configuration else {
            return nil
        }
        self.networkHelper = networkHelper
        self.configuration = configuration
        self.logger = logger
    }

    /// Method that will be called automatically when new configuration is provided.
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        guard let tealiumCollectConfiguration = CollectConfiguration(configuration: configuration, logger: self.logger) else {
            return nil
        }
        self.configuration = tealiumCollectConfiguration
        return self
    }

    /**
     * Sends a list of events to the Tealium Collect service.
     *
     * The provided events need to already be limited by the `dispatchLimit`.
     * In case of multiple events with different `visitorId`s this method will automatically group them by `visitorId` and send them separately.
     * The completion block can, therefore, be called more than once with the list of dispatches that are actually completed every time.
     */
    func dispatch(_ events: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        if events.count == 1 {
            return sendSingleDispatch(events[0], completion: completion)
        } else {
            let batches = batcher.splitDispatchesByVisitorId(events)
            logger?.trace(category: LogCategory.collect,
                          "Collect events split in batches \(batches)")
            let container = DisposeContainer()
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
    func sendSingleDispatch(_ event: Dispatch, completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        var data = event.payload
        batcher.applyProfileOverride(configuration.overrideProfile, to: &data)
        return networkHelper.post(url: configuration.url, body: data) { result in
            if case .failure(.cancelled) = result {
                completion([])
                return
            }
            completion([event])
        }
    }

    /**
     * Sends a list of events to the batch endpoint.
     *
     * The provided events need to already be limited by the `dispatchLimit`
     * and be connected to the same `visitorId` (or eventually no `visitorId`).
     * This method will create the JSON by compressing those batches, eventually apply the `overrideProfile`,
     * and then send the payload with a gzipped POST requst to the batch endpoint.
     */
    func sendBatchDispatches(_ events: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        guard let batchData = batcher.compressDispatches(events, profileOverride: configuration.overrideProfile) else {
            return Subscription { }
        }
        return networkHelper.post(url: configuration.batchUrl, body: batchData) { result in
            if case .failure(.cancelled) = result {
                completion([])
                return
            }
            completion(events)
        }
    }
}
