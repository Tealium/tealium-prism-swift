//
//  TraceModule.swift
//  tealium-prism
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

enum TraceError: Error, ErrorEnum {
    case noActiveTrace
}

class TraceModule: Collector, BasicModule {
    let version: String = TealiumConstants.libraryVersion
    let dataStore: any DataStore
    let tracker: Tracker
    static let moduleType: String = Modules.Types.trace
    var id: String { Self.moduleType }

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: Self.moduleType) else {
            return nil
        }
        self.init(dataStore: dataStore, tracker: context.tracker)
    }

    init(dataStore: any DataStore, tracker: Tracker) {
        self.dataStore = dataStore
        self.tracker = tracker
    }

    func killVisitorSession(onTrackResult: TrackResultCompletion? = nil) throws(TraceError) {
        guard let traceId = dataStore.get(key: TealiumDataKey.tealiumTraceId, as: String.self) else {
            throw TraceError.noActiveTrace
        }
        let dispatch = Dispatch(name: TealiumConstants.killVisitorSessionQueryParam,
                                data: [
                                    TealiumDataKey.killVisitorSessionEvent: TealiumConstants.killVisitorSessionQueryParam,
                                    TealiumDataKey.cpTraceId: traceId,
                                    TealiumDataKey.tealiumTraceId: traceId
                                ])
        tracker.track(dispatch, source: .module(TraceModule.self), onTrackResult: onTrackResult)
    }

    func join(id: String) throws {
        try dataStore.edit()
            .put(key: TealiumDataKey.tealiumTraceId, value: id, expiry: .session)
            .commit()
    }

    func leave() throws {
        try dataStore.edit()
            .remove(key: TealiumDataKey.tealiumTraceId)
            .commit()
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        var result = dataStore.getAll()
        if let traceId = result.get(key: TealiumDataKey.tealiumTraceId, as: String.self) {
            result.set(traceId, key: TealiumDataKey.cpTraceId) // adding a twin for retrocompatibility
        }
        return result
    }
}
