//
//  TraceModule.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class TraceModule: Collector, BasicModule {
    let version: String = TealiumConstants.libraryVersion
    let dataStore: DataStore
    let tracker: Tracker
    static let moduleType: String = Modules.Types.trace
    var id: String { Self.moduleType }

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: Self.moduleType) else {
            return nil
        }
        self.init(dataStore: dataStore, tracker: context.tracker)
    }

    init(dataStore: DataStore, tracker: Tracker) {
        self.dataStore = dataStore
        self.tracker = tracker
    }

    func killVisitorSession(onTrackResult: TrackResultCompletion? = nil) throws {
        guard let traceId = dataStore.get(key: TealiumDataKey.traceId, as: String.self) else {
            throw TealiumError.genericError("Not in an active Trace")
        }
        let dispatch = Dispatch(name: TealiumKey.killVisitorSession,
                                data: [
                                    TealiumDataKey.killVisitorSessionEvent: TealiumKey.killVisitorSession,
                                    TealiumDataKey.traceId: traceId
                                ])
        tracker.track(dispatch, source: .module(TraceModule.self), onTrackResult: onTrackResult)
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
        guard dispatchContext.source.moduleType != TraceModule.self else {
            return DataObject()
        }
        return dataStore.getAll()
    }
}
