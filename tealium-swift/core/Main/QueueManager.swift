//
//  QueueManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class QueueManager {
    /// [DispatcherId: [DispatchId]]
    var inflightEvents = [String: [String]]() {
        didSet {
            _onInflightEvents.publish(inflightEvents)
        }
    }

    @ToAnyObservable<TealiumReplaySubject<[String: [String]]>>(TealiumReplaySubject<[String: [String]]>())
    var onInflightEvents: TealiumObservable<[String: [String]]>
    @ToAnyObservable<TealiumPublisher<Void>>(TealiumPublisher<Void>())
    var onEnqueuedEvents: TealiumObservable<Void>

    func onInflightEventsCount(for dispatcher: Dispatcher) -> TealiumObservable<Int> {
        onInflightEvents.map { events in
            events[dispatcher.id]?.count ?? 0
        }.distinct()
    }

    func getQueuedEvents(for dispatcher: Dispatcher, limit: Int) -> [TealiumDispatch] {
        // query from disk, filtering from inflight
        // add returned events to inflight
        return []
    }

    func storeDispatch(_ dispatch: TealiumDispatch, for dispatchers: [String]?) {
        let dispatchers = dispatchers ?? [] // All otherwise
        guard !dispatchers.isEmpty else { return }
        // add to disk
        _onEnqueuedEvents.publish()
    }

    func deleteDispatches(_ dispatches: [TealiumDispatch], for dispatcher: Dispatcher) {
        let dispatcherId = dispatcher.id
        inflightEvents[dispatcherId] = inflightEvents[dispatcherId]?.filter { inFlightDispatch in
            !dispatches.contains { $0.id == inFlightDispatch }
        } ?? []
        // delete from disk
    }

    func clear() {
        inflightEvents.removeAll()
        // delete from disk
    }
}
