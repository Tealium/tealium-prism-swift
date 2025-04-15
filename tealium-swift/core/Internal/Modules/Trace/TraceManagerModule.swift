//
//  TraceManagerModule.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class TraceManagerModule: Collector {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "Trace"
    let dataStore: DataStore
    let tracker: Tracker

    init(dataStore: DataStore, tracker: Tracker) {
        self.dataStore = dataStore
        self.tracker = tracker
    }

    func killVisitorSession(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let traceId = dataStore.get(key: TealiumDataKey.traceId, as: String.self) else {
            completion?(.failure(TealiumError.genericError("Not in an active Trace")))
            return
        }
        let dispatch = TealiumDispatch(name: TealiumKey.killVisitorSession,
                                       data: [
                                        TealiumDataKey.killVisitorSessionEvent: TealiumKey.killVisitorSession,
                                        TealiumDataKey.traceId: traceId
                                       ])
        tracker.track(dispatch, source: .module(TraceManagerModule.self)) { _, result in
            if result == .dropped {
                completion?(.failure(TealiumError.genericError("Kill Visitor Session event was dropped.")))
            } else {
                completion?(.success(()))
            }
        }
    }

    func join(id: String) throws {
        try dataStore.edit()
            .put(key: TealiumDataKey.traceId, value: id, expiry: .session)
            .commit()
    }

    func leave() throws {
        try dataStore.edit()
            .remove(key: TealiumDataKey.traceId)
            .commit()
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        guard dispatchContext.source.moduleType != TraceManagerModule.self else {
            return DataObject()
        }
        return dataStore.getAll()
    }
}
