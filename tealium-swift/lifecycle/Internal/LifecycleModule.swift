//
//  LifecycleModule.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class LifecycleModule: Collector {
    static let id: String = "Lifecycle"

    // MARK: Collector
    var data: DataObject {
        return if lifecycleSettings.dataTarget == LifecycleDataTarget.allEvents {
            lifecycleService.getCurrentState(timestamp: Date().unixTimeMillisecondsInt)
        } else {
            DataObject()
        }
    }

    private var lifecycleSettings: LifecycleSettings
    internal let lifecycleService: LifecycleService

    weak private var tracker: Tracker? // it's weak in the context, so should be kept that way
    private let logger: LoggerProtocol?
    private let automaticDisposer: AutomaticDisposer = AutomaticDisposer()

    private var lastBackground: Int64?
    private var hasLaunched = false
    private var shouldSkipNextForeground = false
    private var isInfiniteSession: Bool {
        lifecycleSettings.sessionTimeoutInMinutes <= LifecycleConstants.infiniteSession
    }

    convenience init(context: TealiumContext, settings: LifecycleSettings, service: LifecycleService) {
        self.init(tracker: context.tracker,
                  onApplicationStatus: context.activityListener.onApplicationStatus,
                  settings: settings,
                  service: service,
                  logger: context.logger)
    }

    init(tracker: Tracker?, onApplicationStatus: Observable<ApplicationStatus>, settings: LifecycleSettings, service: LifecycleService, logger: LoggerProtocol?) {
        self.tracker = tracker
        self.lifecycleSettings = settings
        self.lifecycleService = service
        self.logger = logger
        subscribeToApplicationStatus(onApplicationStatus).addTo(automaticDisposer)
    }

    func launch(data: DataObject? = nil) throws {
        if lifecycleSettings.autoTrackingEnabled {
            throw LifecycleError.manualTrackNotAllowed
        }

        try registerLifecycleEvent(event: LifecycleEvent.launch, timestamp: Date().unixTimeMillisecondsInt, data: data)
    }

    func wake(data: DataObject? = nil) throws {
        if lifecycleSettings.autoTrackingEnabled {
            throw LifecycleError.manualTrackNotAllowed
        }

        try registerLifecycleEvent(event: LifecycleEvent.wake, timestamp: Date().unixTimeMillisecondsInt, data: data)
    }

    func sleep(data: DataObject? = nil) throws {
        if lifecycleSettings.autoTrackingEnabled {
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
                self.tracker?.track(dispatch)
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
        return lifecycleSettings.trackedLifecycleEvents.contains(event)
    }

    private func subscribeToApplicationStatus(_ onApplicationStatus: Observable<ApplicationStatus>) -> Disposable {
        onApplicationStatus.filter { [weak self] _ in
            self?.lifecycleSettings.autoTrackingEnabled ?? false
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
    func updateSettings(_ settings: DataObject) -> Self? {
        lifecycleSettings = LifecycleSettings(moduleSettings: settings)
        return self
    }

    func shutdown() {
        automaticDisposer.dispose()
    }

    private func isExpiredSession(timeElapsed: Int64) -> Bool {
        return timeElapsed > minutesToMillis(minutes: lifecycleSettings.sessionTimeoutInMinutes)
    }

    private func minutesToMillis(minutes: Int) -> Int64 {
        return Int64(minutes * 60 * 1000)
    }

// TODO: do we need this property on LifecycleModule ?
//    override let version: String
//        get() = BuildConfig.TEALIUM_LIBRARY_VERSION
}

extension LifecycleModule {
    class Factory: TealiumModuleFactory {
        typealias Module = LifecycleModule

        private var settings: DataObject?

        init(forcingSettings block: ((_ enforcedSettings: LifecycleSettingsBuilder) -> LifecycleSettingsBuilder)? = nil) {
            settings = block?(LifecycleSettingsBuilder()).build()
        }

        func getEnforcedSettings() -> DataObject? {
            return settings
        }

        func create(context: TealiumContext, moduleSettings settings: DataObject) -> Module? {
            guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: LifecycleModule.id) else {
                return nil
            }
            return LifecycleModule(
                context: context,
                settings: LifecycleSettings(moduleSettings: settings),
                service: LifecycleService(lifecycleStorage: LifecycleStorage(dataStore: dataStore), bundle: context.config.bundle)
            )
        }
    }
}
