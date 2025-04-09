//
//  LifecycleModule.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class LifecycleModule {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "Lifecycle"

    private var configuration: LifecycleConfiguration
    internal let lifecycleService: LifecycleService

    private var tracker: Tracker
    private let logger: LoggerProtocol?
    private let automaticDisposer: AutomaticDisposer = AutomaticDisposer()

    private var lastBackground: Int64?
    private var hasLaunched = false
    private var shouldSkipNextForeground = false
    private var isInfiniteSession: Bool {
        configuration.sessionTimeoutInMinutes <= LifecycleConstants.infiniteSession
    }

    convenience init(context: TealiumContext, configuration: LifecycleConfiguration, service: LifecycleService) {
        self.init(tracker: context.tracker,
                  onApplicationStatus: context.activityListener.onApplicationStatus,
                  configuration: configuration,
                  service: service,
                  logger: context.logger)
    }

    init(tracker: Tracker, onApplicationStatus: Observable<ApplicationStatus>, configuration: LifecycleConfiguration, service: LifecycleService, logger: LoggerProtocol?) {
        self.tracker = tracker
        self.configuration = configuration
        self.lifecycleService = service
        self.logger = logger
        subscribeToApplicationStatus(onApplicationStatus).addTo(automaticDisposer)
    }

    func launch(data: DataObject? = nil) throws {
        if configuration.autoTrackingEnabled {
            throw LifecycleError.manualTrackNotAllowed
        }

        try registerLifecycleEvent(event: LifecycleEvent.launch, timestamp: Date().unixTimeMillisecondsInt, data: data)
    }

    func wake(data: DataObject? = nil) throws {
        if configuration.autoTrackingEnabled {
            throw LifecycleError.manualTrackNotAllowed
        }

        try registerLifecycleEvent(event: LifecycleEvent.wake, timestamp: Date().unixTimeMillisecondsInt, data: data)
    }

    func sleep(data: DataObject? = nil) throws {
        if configuration.autoTrackingEnabled {
            throw LifecycleError.manualTrackNotAllowed
        }

        try registerLifecycleEvent(event: LifecycleEvent.sleep, timestamp: Date().unixTimeMillisecondsInt, data: data)
    }

    private func isAcceptable(_ event: LifecycleEvent) -> Bool {
        let lastEvent = lifecycleService.lastLifecycleEvent
        var result: Bool = true
        switch event {
        case .launch:
            if hasLaunched && lastEvent != .sleep {
                result = false
            }
        case .sleep:
            if lastEvent != .wake && lastEvent != .launch {
                result = false
            }
        case .wake:
            if lastEvent != .sleep {
                result = false
            }
        }
        return result
    }

    private func registerLifecycleEvent(
        event: LifecycleEvent,
        timestamp: Int64,
        data: DataObject?
    ) throws {
        do {
            guard isAcceptable(event) else {
                throw LifecycleError.invalidEventOrder
            }
            var state = switch event {
            case .launch:
                try lifecycleService.registerLaunch(timestamp: timestamp)
            case .wake:
                try lifecycleService.registerWake(timestamp: timestamp)
            case .sleep:
                try lifecycleService.registerSleep(timestamp: timestamp)
            }
            if isTrackableEvent(event: event) {
                if let data {
                    state += data
                }
                let dispatch = TealiumDispatch(name: event.rawValue, data: state)
                self.tracker.track(dispatch, source: .module(LifecycleModule.self))
            }
            if !hasLaunched {
                hasLaunched = true
            }
        } catch {
            self.logger?.error(category: LogCategory.lifecycle, "Failed to process lifecycle event \(event)\nError: \(error)")
            throw error
        }
    }

    private func isTrackableEvent(event: LifecycleEvent) -> Bool {
        return configuration.trackedLifecycleEvents.contains(event)
    }

    private func subscribeToApplicationStatus(_ onApplicationStatus: Observable<ApplicationStatus>) -> Disposable {
        onApplicationStatus.filter { [weak self] _ in
            self?.configuration.autoTrackingEnabled ?? false
        }
        .subscribe { [weak self] newStatus in
            guard let self else {
                return
            }
            if !self.hasLaunched {
                handleFirstLaunch(status: newStatus)
            } else {
                handleApplicationStatus(status: newStatus)
            }
        }
    }

    func handleFirstLaunch(status: ApplicationStatus) {
        let timestamp = Date().unixTimeMillisecondsInt
        switch status.type {
        case .initialized:
            self.handleApplicationStatus(status: status)
            self.shouldSkipNextForeground = true // to skip registering first .foregrounded status emitted after launch
        case .foregrounded:
            self.handleApplicationStatus(status: ApplicationStatus(type: .initialized, timestamp: timestamp))
        case .backgrounded:
            self.handleApplicationStatus(status: ApplicationStatus(type: .initialized, timestamp: timestamp))
            self.handleApplicationStatus(status: ApplicationStatus(type: .backgrounded, timestamp: timestamp))
        }
    }

    func handleApplicationStatus(status: ApplicationStatus) {
        let shouldSkipHandling = status.type == .foregrounded && shouldSkipNextForeground
        guard !shouldSkipHandling else {
            shouldSkipNextForeground = false
            return
        }
        let dataObject: DataObject = [LifecycleStateKey.autotracked: true]
        switch status.type {
        case .initialized:
            try? self.registerLifecycleEvent(
                event: LifecycleEvent.launch,
                timestamp: status.timestamp,
                data: dataObject
            )
        case .foregrounded:
            var timeDifference: Int64 = 0
            if let lastBackground = self.lastBackground {
                timeDifference = status.timestamp - lastBackground
            }

            if !self.isInfiniteSession && isExpiredSession(timeElapsed: timeDifference) {
                try? self.registerLifecycleEvent(
                    event: LifecycleEvent.launch,
                    timestamp: status.timestamp,
                    data: dataObject
                )
            } else {
                try? self.registerLifecycleEvent(
                    event: LifecycleEvent.wake,
                    timestamp: status.timestamp,
                    data: dataObject
                )
            }
        case .backgrounded:
            self.lastBackground = status.timestamp
            try? self.registerLifecycleEvent(
                event: LifecycleEvent.sleep,
                timestamp: status.timestamp,
                data: dataObject
            )
            if self.shouldSkipNextForeground {
                self.shouldSkipNextForeground = false
            }
        }
    }

    // MARK: TealiumModule
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        self.configuration = LifecycleConfiguration(configuration: configuration)
        return self
    }

    func shutdown() {
        automaticDisposer.dispose()
    }

    private func isExpiredSession(timeElapsed: Int64) -> Bool {
        return timeElapsed > minutesToMillis(minutes: configuration.sessionTimeoutInMinutes)
    }

    private func minutesToMillis(minutes: Int) -> Int64 {
        return Int64(minutes * 60 * 1000)
    }
}

extension LifecycleModule: Collector {
    // MARK: Collector
    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        guard configuration.dataTarget == LifecycleDataTarget.allEvents
                && dispatchContext.source.moduleType != LifecycleModule.self
        else {
            return DataObject()
        }
        return lifecycleService.getCurrentState(timestamp: Date().unixTimeMillisecondsInt)
    }
}
