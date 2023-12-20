//
//  QueueManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

protocol QueueManagerProtocol {
    var onEnqueuedEvents: TealiumObservable<Void> { get }
    func onInflightEventsCount(for dispatcher: Dispatcher) -> TealiumObservable<Int>
    func getQueuedEvents(for dispatcher: Dispatcher, limit: Int) -> [TealiumDispatch]
    func storeDispatch(_ dispatch: TealiumDispatch, for dispatchers: [String]?)
    func deleteDispatches(_ dispatches: [TealiumDispatch], for dispatcher: Dispatcher)
    func clear()
}

class QueueManager: QueueManagerProtocol {
    struct QueueItem {
        let dispatch: TealiumDispatch
        var dispatchers: [String]
    }
    /// [DispatcherId: [DispatchId]]
    var inflightEvents = [String: [String]]() {
        didSet {
            _onInflightEvents.publish(inflightEvents)
        }
    }

    var queue = [QueueItem]()

    @ToAnyObservable<TealiumReplaySubject<[String: [String]]>>(TealiumReplaySubject<[String: [String]]>(initialValue: [:]))
    var onInflightEvents: TealiumObservable<[String: [String]]>
    @ToAnyObservable<TealiumPublisher<Void>>(TealiumPublisher<Void>())
    var onEnqueuedEvents: TealiumObservable<Void>
    let modulesManager: ModulesManager

    init(modulesManager: ModulesManager) {
        self.modulesManager = modulesManager
    }

    func onInflightEventsCount(for dispatcher: Dispatcher) -> TealiumObservable<Int> {
        onInflightEvents.map { events in
            events[dispatcher.id]?.count ?? 0
        }.distinct()
    }

    func getQueuedEvents(for dispatcher: Dispatcher, limit: Int) -> [TealiumDispatch] {
        let dispatcherId = dispatcher.id
        let events = queue
            .filter { $0.dispatchers.contains(dispatcherId) }
            .map { $0.dispatch }
            .filter { inflightEvents[dispatcherId]?.contains($0.id) != true }
            .prefix(limit)
        var inflight = inflightEvents
        for event in events {
            inflight[dispatcherId] = (inflight[dispatcherId] ?? []) + [event.id]
        }
        inflightEvents = inflight
        return Array(events)
    }

    func storeDispatch(_ dispatch: TealiumDispatch, for dispatchers: [String]?) {
        let dispatchers = dispatchers ?? modulesManager.modules.value
            .filter { $0 is Dispatcher }
            .map { $0.id }
        guard !dispatchers.isEmpty else { return }
        queue.append(QueueItem(dispatch: dispatch, dispatchers: dispatchers))
        _onEnqueuedEvents.publish()
    }

    func deleteDispatches(_ dispatches: [TealiumDispatch], for dispatcher: Dispatcher) {
        let dispatcherId = dispatcher.id
        queue = queue.compactMap { queueItem in
            var queueItem = queueItem
            if dispatches.contains(where: { queueItem.dispatch.id == $0.id }) {
                queueItem.dispatchers = queueItem.dispatchers.filter { $0 != dispatcherId }
                if queueItem.dispatchers.isEmpty {
                    return nil
                }
            }
            return queueItem
        }
        inflightEvents[dispatcherId] = inflightEvents[dispatcherId]?.filter { inFlightDispatch in
            !dispatches.contains { $0.id == inFlightDispatch }
        } ?? []
    }

    func clear() {
        inflightEvents.removeAll()
        queue.removeAll()
    }
}
