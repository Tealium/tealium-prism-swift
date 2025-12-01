//
//  TraceModule.swift
//  tealium-prism
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

enum TraceError: Error, ErrorEnum {
    case noActiveTrace
}

class TraceModule: Collector, BasicModule {
    let version: String = TealiumConstants.libraryVersion
    let dataStore: any DataStore
    let tracker: Tracker
    static let moduleType: String = Modules.Types.trace
    var id: String { Self.moduleType }
    var trackErrors = false
    var onErrorEvent: Observable<ErrorEvent>?
    private var errorSubscription: Disposable?

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: Self.moduleType) else {
            return nil
        }
        self.init(dataStore: dataStore,
                  tracker: context.tracker,
                  configuration: TraceModuleConfiguration(configuration: moduleConfiguration),
                  onErrorEvent: (context.logger as? TealiumLogger)?.onError)
    }

    init(dataStore: any DataStore, tracker: Tracker, configuration: TraceModuleConfiguration, onErrorEvent: Observable<ErrorEvent>? = nil) {
        self.dataStore = dataStore
        self.tracker = tracker
        self.onErrorEvent = onErrorEvent
        self.trackErrors = configuration.trackErrors
    }

    func forceEndOfVisit(onTrackResult: TrackResultCompletion? = nil) throws(TraceError) {
        guard let traceId = dataStore.get(key: TealiumDataKey.tealiumTraceId, as: String.self) else {
            throw TraceError.noActiveTrace
        }
        let dispatch = Dispatch(name: TealiumConstants.forceEndOfVisitQueryParam,
                                // adding trace ID is left here JIC if collect is rejected by some Rule
                                data: [
                                    TealiumDataKey.forceEndOfVisitEvent: TealiumConstants.forceEndOfVisitQueryParam,
                                    TealiumDataKey.cpTraceId: traceId,
                                    TealiumDataKey.tealiumTraceId: traceId
                                ])
        tracker.track(dispatch, source: .module(TraceModule.self), onTrackResult: onTrackResult)
    }

    func join(id: String) throws {
        try dataStore.edit()
            .put(key: TealiumDataKey.tealiumTraceId, value: id, expiry: .session)
            .commit()
        subscribeToErrors()
    }

    func leave() throws {
        try dataStore.edit()
            .remove(key: TealiumDataKey.tealiumTraceId)
            .commit()
        errorSubscription?.dispose()
    }

    private func subscribeToErrors() {
        guard let onErrorEvent else { return }
        errorSubscription?.dispose()
        errorSubscription = onErrorEvent.filter { [weak self] _ in self?.trackErrors == true }
            .subscribe { [weak self] errorEvent in
                self?.trackError(errorEvent)
            }
    }

    private func trackError(_ errorEvent: ErrorEvent) {
        let errorDispatch = Dispatch(
            name: "tealium_error",
            type: .event,
            data: ["error_description": errorEvent.description]
        )
        tracker.track(errorDispatch, source: .module(TraceModule.self))
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        var result = dataStore.getAll()
        if let traceId = result.get(key: TealiumDataKey.tealiumTraceId, as: String.self) {
            result.set(traceId, key: TealiumDataKey.cpTraceId) // adding a twin for retrocompatibility
        }
        return result
    }

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        let moduleConfig = TraceModuleConfiguration(configuration: configuration)
        self.trackErrors = moduleConfig.trackErrors
        return self
    }

    deinit {
        errorSubscription?.dispose()
    }
}

extension TealiumDataKey {
    /// Event key for force end of visit call.
    static let forceEndOfVisitEvent = "event"
}
