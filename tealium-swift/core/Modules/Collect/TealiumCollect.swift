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
public class TealiumCollect: Dispatcher {
    public static let id: String = "collect"
    public let dispatchLimit = 10
    let batcher = CollectBatcher()
    let networkHelper: NetworkHelperProtocol
    let logger: TealiumLoggerProvider?
    var settings: TealiumCollectSettings

    /// Generic `Dispatcher` initializer called by the `ModulesManager`.
    public required convenience init(context: TealiumContext, moduleSettings: [String: Any]) {
        self.init(networkHelper: context.networkHelper,
                  settings: TealiumCollectSettings(moduleSettings: moduleSettings),
                  logger: context.logger)
    }

    /// Internal initalizer called by the generic one and by the tests.
    init(networkHelper: NetworkHelperProtocol, settings: TealiumCollectSettings, logger: TealiumLoggerProvider? = nil) {
        self.networkHelper = networkHelper
        self.settings = settings
        self.logger = logger
    }

    /// Method that will be called automatically when new settings are provided.
    public func updateSettings(_ settings: [String: Any]) -> Self? {
        self.settings = TealiumCollectSettings(moduleSettings: settings)
        logger?.trace?.log(category: TealiumLibraryCategories.settings, message: "Collect settings updated \(self.settings)")
        return self
    }

    /**
     * Sends a list of events to the Tealium Collect service.
     *
     * The provided events need to already be limited by the `dispatchLimit`.
     * In case of multiple events with different `visitorId`s this method will automatically group them by `visitorId` and send them separately.
     * The completion block can, therefore, be called more than once with the list of dispatches that are actually completed every time.
     */
    public func dispatch(_ events: [TealiumDispatch], completion: @escaping ([TealiumDispatch]) -> Void) {
        logger?.trace?.log(category: TealiumLibraryCategories.dispatching,
                           message: "Collect dispatching events \(events.map { $0.eventData })")
        if events.count == 1 {
            sendSingleDispatch(events[0], completion: completion)
        } else {
            let batches = batcher.splitDispatchesByVisitorId(events)
            logger?.trace?.log(category: TealiumLibraryCategories.dispatching,
                               message: "Collect events split in batches \(batches)")
            for batch in batches where !batch.isEmpty {
                if batch.count == 1 {
                    sendSingleDispatch(batch[0], completion: completion)
                } else {
                    sendBatchDispatches(batch, completion: completion)
                }
            }
        }
    }

    /**
     * Sends an event to the single event endpoint.
     *
     * This method will create the JSON, eventually apply the `overrideProfile`,
     * and then send the gzipped payload with a POST request to the batch endpoint.
     */
    func sendSingleDispatch(_ event: TealiumDispatch, completion: @escaping ([TealiumDispatch]) -> Void) {
        logger?.debug?.log(category: TealiumLibraryCategories.dispatching,
                           message: "Collect dispatching event \(event.name ?? "unknown")")
        guard let url = settings.url else {
            logger?.error?.log(category: TealiumLibraryCategories.dispatching,
                               message: "Collect failed to dispatch due to settings with no URL to dispatch")
            return
        }
        var data: [String: Any] = event.eventData
        batcher.applyProfileOverride(settings.overrideProfile, to: &data)
        _ = networkHelper.post(url: url, body: data) { [weak self] result in
            self?.logger?.debug?
                .log(category: TealiumLibraryCategories.dispatching,
                     message: "Collect dispatching \(result.shortDescription()) for event \(event.name ?? "unknown")")
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
    func sendBatchDispatches(_ events: [TealiumDispatch], completion: @escaping ([TealiumDispatch]) -> Void) {
        logger?.debug?.log(category: TealiumLibraryCategories.dispatching,
                           message: "Collect dispatching events \(events.map { $0.name ?? "unknown" })")
        guard let url = settings.batchUrl,
              let batchData = batcher.compressDispatches(events, profileOverride: settings.overrideProfile) else {
                logger?.error?.log(category: TealiumLibraryCategories.dispatching,
                                   message: "Collect failed to disptch due to settings with no batch URL to dispatch")
            return
        }
        _ = networkHelper.post(url: url, body: batchData) { [weak self] result in
            self?.logger?.debug?
                .log(category: TealiumLibraryCategories.dispatching,
                     message: "Collect dispatching \(result.shortDescription()) for events \(events.map { $0.name ?? "unknown" })")
            completion(events)
        }
    }
}
