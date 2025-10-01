//
//  QueueManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class QueueManager: QueueManagerProtocol {
    /// [DispatcherId: [DispatchId]]
    @StateSubject([String: Set<String>]())
    var inflightEvents: ObservableState<[String: Set<String>]>
    @ToAnyObservable<BasePublisher<Set<String>>>(BasePublisher<Set<String>>())
    var onEnqueuedDispatchesForProcessors: Observable<Set<String>>
    @ToAnyObservable<BasePublisher<Set<String>>>(BasePublisher<Set<String>>())
    var onDeletedDispatchesForProcessors: Observable<Set<String>>
    private let queueRepository: QueueRepository
    private let disposer = AutomaticDisposer()
    private let logger: LoggerProtocol?
    init(processors: Observable<[String]>, queueRepository: QueueRepository, coreSettings: ObservableState<CoreSettings>, logger: LoggerProtocol?) {
        self.queueRepository = queueRepository
        self.logger = logger
        processors.subscribe { [weak self] processors in
            self?.deleteQueues(forProcessorsNotIn: processors)
        }.addTo(disposer)
        coreSettings.subscribe { [weak self] settings in
            self?.handleSettingsUpdate(settings)
        }.addTo(disposer)
    }

    private func handleSettingsUpdate(_ settings: CoreSettings) {
        let affectedProcessors = calculateProcessorDeletions {
            do {
                try queueRepository.resize(newSize: settings.maxQueueSize)
                logger?.debug(category: LogCategory.queueManager,
                              "Resized the queue to \(settings.maxQueueSize) and deleted eventual overflowing dispatches")
            } catch {
                logger?.error(category: LogCategory.queueManager,
                              "Failed to delete dispatches exceeding the maxQueueSize of \(settings.maxQueueSize)\nError: \(error)")
            }
            do {
                try queueRepository.setExpiration(settings.queueExpiration)
                logger?.debug(category: LogCategory.queueManager,
                              "Set Queue Expiration to \(settings.queueExpiration) and deleted all expired dispatches")
            } catch {
                logger?.error(category: LogCategory.queueManager,
                              "Failed to delete expired dispatches for expiration \(settings.queueExpiration)\nError: \(error)")
            }
        }
        onProcessorsDeleted(processors: Set(affectedProcessors))
    }

    private func calculateProcessorDeletions(_ task: () throws -> Void) rethrows -> [String] {
        let initialQueueSizes = queueRepository.queueSizeByProcessor()
        try task()
        let afterQueueSizes = queueRepository.queueSizeByProcessor()
        let affectedProcessors = initialQueueSizes.compactMap { processor, size in
            if let newSize = afterQueueSizes[processor] {
                // return processor if its queue size was reduced
                return newSize < size ? processor : nil
            } else {
                // or if processor queue was removed
                return processor
            }
        }
        return affectedProcessors
    }

    private func deleteQueues(forProcessorsNotIn processors: [String]) {
        do {
            let affectedProcessors = try calculateProcessorDeletions {
                try self.queueRepository.deleteQueues(forProcessorsNotIn: processors)
                logger?.debug(category: LogCategory.queueManager,
                              "Deleted queued events for disabled processors. Currently enabled processors are: \(processors)")
            }
            onProcessorsDeleted(processors: Set(affectedProcessors))
        } catch {
            logger?.error(category: LogCategory.queueManager,
                          "Failed to delete queued events for disabled processors. Currently enabled processors are: \(processors)\nError: \(error)")
        }
    }

    func onQueueSizePendingDispatch(for processorId: String) -> Observable<Int> {
        let queueSizeChanges = onEnqueuedDispatchesForProcessors
            .merge(onDeletedDispatchesForProcessors)
            .filter { $0.contains(processorId) }
            .map { _ in () }
        return queueSizeChanges
            .startWith(())
            .map { [queueRepository] _ in queueRepository.queueSize(for: processorId) }
            .combineLatest(onInflightDispatchesCount(for: processorId))
            .map { queueSize, inflight in
                max(queueSize - inflight, 0)
            }
            .distinct()
    }

    func onInflightDispatchesCount(for processor: String) -> Observable<Int> {
        inflightEvents.asObservable().map { events in
            events[processor]?.count ?? 0
        }.distinct()
    }

    func dequeueDispatches(for processor: String, limit: Int?) -> [Dispatch] {
        let dispatches = peekDispatches(for: processor, limit: limit)
        guard !dispatches.isEmpty else {
            return []
        }
        logger?.debug(category: LogCategory.queueManager,
                      "Dequeued dispatches for processor \(processor): \(dispatches.map { $0.logDescription() })")
        addToInflightDispatches(processor: processor, dispatches: dispatches)
        return dispatches
    }

    /**
     * Returns the `Dispatch`es in the queue, up to an optional limit,  excluding the current inflight events
     * but without saving them as inflight.
     *
     * - Parameters:
     *   - processor: The `processor` from which `Dispatch`es need to be dequeued from.
     *   - limit: The optional maximum amount of dispatches to dequeue.
     *
     * - Returns: A list of `Dispatch`es, ordered by timestamp, starting from the latest inflight dispatch.
     */
    func peekDispatches(for processor: String, limit: Int?) -> [Dispatch] {
        let inflightSet = inflightEvents.value[processor] ?? Set<String>()
        return queueRepository.getQueuedDispatches(for: processor,
                                                   limit: limit,
                                                   excluding: Array(inflightSet))
    }

    private func addToInflightDispatches(processor: String, dispatches: [Dispatch]) {
        var eventsInflight = inflightEvents.value
        let dispatchIds = dispatches.map { $0.id }
        var inflightDispatchesSet = eventsInflight[processor] ?? Set<String>()
        inflightDispatchesSet.formUnion(dispatchIds)
        eventsInflight[processor] = inflightDispatchesSet
        _inflightEvents.value = eventsInflight
    }

    func storeDispatches(_ dispatches: [Dispatch], enqueueingFor processors: [String]) {
        guard !dispatches.isEmpty && !processors.isEmpty else {
            return
        }
        do {
            try queueRepository.storeDispatches(dispatches, enqueueingFor: processors)
            logger?.debug(category: LogCategory.queueManager,
                          "Enqueued dispatches for processors \(processors): \(dispatches.map { $0.logDescription() })")
            _onEnqueuedDispatchesForProcessors.publish(Set(processors))
        } catch {
            logger?.error(category: LogCategory.queueManager,
                          "Failed to enqueue dispatches for processors \(processors): \(dispatches.map { $0.logDescription() })\nError: \(error)")
        }
    }

    func deleteDispatches(_ dispatchUUIDs: [String], for processor: String) {
        do {
            try queueRepository.deleteDispatches(dispatchUUIDs, for: processor)
            logger?.debug(category: LogCategory.queueManager,
                          "Removed processed dispatches for processor \(processor): \(dispatchUUIDs)")
            onDispatchesDeleted(processor: processor, dispatchUUIDs: dispatchUUIDs)
        } catch {
            logger?.error(category: LogCategory.queueManager,
                          "Failed to remove processed dispatches for processor \(processor): \(dispatchUUIDs)\nError: \(error)")
        }
    }

    private func onDispatchesDeleted(processor: String, dispatchUUIDs: [String]) {
        guard !dispatchUUIDs.isEmpty else { return }
        _onDeletedDispatchesForProcessors.publish([processor])
        var eventsInflight = inflightEvents.value
        let remaining = (eventsInflight[processor] ?? Set<String>()).subtracting(dispatchUUIDs)
        eventsInflight[processor] = remaining
        _inflightEvents.value = eventsInflight
    }

    func deleteAllDispatches(for processor: String) {
        do {
            try queueRepository.deleteAllDispatches(for: processor)
            logger?.debug(category: LogCategory.queueManager,
                          "Removed all processed dispatches for processor \(processor)")
            onProcessorsDeleted(processors: Set([processor]))
        } catch {
            logger?.error(category: LogCategory.queueManager,
                          "Failed to remove all processed dispatches for processor \(processor)\nError: \(error)")
        }
    }

    private func onProcessorsDeleted(processors: Set<String>) {
        guard !processors.isEmpty else {
            return
        }
        _onDeletedDispatchesForProcessors.publish(processors)
        let eventsInflight = inflightEvents.value.filter { !processors.contains($0.key) }
        _inflightEvents.value = eventsInflight
    }
}
