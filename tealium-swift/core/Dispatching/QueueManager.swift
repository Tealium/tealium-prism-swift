//
//  QueueManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class QueueManager: QueueManagerProtocol {
    /// [DispatcherId: [DispatchId]]
    @StateSubject([String: [String]]())
    var inflightEvents: ObservableState<[String: [String]]>
    @ToAnyObservable<BasePublisher<[String]>>(BasePublisher<[String]>())
    var onEnqueuedDispatchesForProcessors: Observable<[String]>
    let queueRepository: QueueRepository
    let disposer = AutomaticDisposer()
    let logger: TealiumLogger?
    init(processors: Observable<[String]>, queueRepository: QueueRepository, coreSettings: ObservableState<CoreSettings>, logger: TealiumLogger? = nil) {
        self.queueRepository = queueRepository
        self.logger = logger
        processors.subscribe { [weak self] processors in
            self?.deleteQueues(forProcessorsNotIn: processors)
        }.addTo(disposer)
        coreSettings.subscribe { settings in
            do {
                try queueRepository.resize(newSize: settings.maxQueueSize)
                logger?.debug?.log(category: LogCategory.queueManager, message: "Resized the queue to \(settings.maxQueueSize) and deleted eventual overflowing dispatches")
            } catch {
                logger?.error?.log(category: LogCategory.queueManager, message: "Failed to delete dispatches exceeding the maxQueueSize of \(settings.maxQueueSize)\nError: \(error)")
            }
            do {
                try queueRepository.setExpiration(settings.queueExpiration)
                logger?.debug?.log(category: LogCategory.queueManager, message: "Set Queue Expiration to \(settings.queueExpiration) and deleted all expired dispatches")
            } catch {
                logger?.error?.log(category: LogCategory.queueManager, message: "Failed to delete expired dispatches for expiration \(settings.queueExpiration)\nError: \(error)")
            }
        }.addTo(disposer)
    }

    private func deleteQueues(forProcessorsNotIn processors: [String]) {
        do {
            try self.queueRepository.deleteQueues(forProcessorsNotIn: processors)
            logger?.debug?.log(category: LogCategory.queueManager, message: "Deleted queued events for disabled processors. Currently enabled processors are: \(processors)")
            let removedProcessors = self.inflightEvents.value.keys.filter { processors.contains($0) }
            guard !removedProcessors.isEmpty else {
                return
            }
            var newInflightEvents = self.inflightEvents.value
            for removedProcessor in removedProcessors {
                newInflightEvents.removeValue(forKey: removedProcessor)
            }
            _inflightEvents.value = newInflightEvents
        } catch {
            logger?.error?.log(category: LogCategory.queueManager,
                               message: "Failed to delete queued events for disabled processors. Currently enabled processors are: \(processors)\nError: \(error)")
        }
    }

    func onInflightDispatchesCount(for processor: String) -> Observable<Int> {
        inflightEvents.asObservable().map { events in
            events[processor]?.count ?? 0
        }.distinct()
    }

    func getQueuedDispatches(for processor: String, limit: Int?) -> [TealiumDispatch] {
        let dispatches = queueRepository.getQueuedDispatches(for: processor,
                                                             limit: limit,
                                                             excluding: inflightEvents.value[processor] ?? [])
        guard !dispatches.isEmpty else {
            return []
        }
        logger?.debug?.log(category: LogCategory.queueManager, message: "Dequeued dispatches for processor \(processor): \(dispatches.map { $0.logDescription() })")
        var inflight = inflightEvents.value
        for event in dispatches {
            inflight[processor] = (inflight[processor] ?? []) + [event.id]
        }
        _inflightEvents.value = inflight
        return dispatches
    }

    func storeDispatches(_ dispatches: [TealiumDispatch], enqueueingFor processors: [String]) {
        guard !dispatches.isEmpty && !processors.isEmpty else {
            return
        }
        do {
            try queueRepository.storeDispatches(dispatches, enqueueingFor: processors)
            logger?.debug?.log(category: LogCategory.queueManager, message: "Enqueued dispatches for processors \(processors): \(dispatches.map { $0.logDescription() })")
            _onEnqueuedDispatchesForProcessors.publish(processors)
        } catch {
            logger?.error?.log(category: LogCategory.queueManager,
                               message: "Failed to enqueue dispatches for processors \(processors): \(dispatches.map { $0.logDescription() })\nError: \(error)")
        }
    }

    func deleteDispatches(_ dispatchUUIDs: [String], for processor: String) {
        do {
            try queueRepository.deleteDispatches(dispatchUUIDs, for: processor)
            logger?.debug?.log(category: LogCategory.queueManager, message: "Removed processed dispatches for processor \(processor): \(dispatchUUIDs)")
            _inflightEvents.value[processor] = inflightEvents.value[processor]?.filter { inFlightDispatch in
                !dispatchUUIDs.contains { $0 == inFlightDispatch }
            } ?? []
        } catch {
            logger?.error?.log(category: LogCategory.queueManager, message: "Failed to remove processed dispatches for processor \(processor): \(dispatchUUIDs)\nError: \(error)")
        }
    }

    func deleteAllDispatches(for processor: String) {
        do {
            try queueRepository.deleteAllDispatches(for: processor)
            logger?.debug?.log(category: LogCategory.queueManager, message: "Removed all processed dispatches for processor \(processor)")
            _inflightEvents.value[processor] = []
        } catch {
            logger?.error?.log(category: LogCategory.queueManager, message: "Failed to remove all processed dispatches for processor \(processor)\nError: \(error)")
        }
    }
}
