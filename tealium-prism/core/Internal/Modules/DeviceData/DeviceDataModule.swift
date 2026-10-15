//
//  DeviceDataModule.swift
//  tealium-prism
//
//  Created by Den Guzov on 13/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#endif

class DeviceDataModule: Collector, Transformer, BasicModule {
    let version: String = TealiumConstants.libraryVersion
    private let deviceDataProvider: DeviceDataProvider
    private let networkHelper: NetworkHelperProtocol
    private let logger: LoggerProtocol?
    private let dataStore: (any DataStore)?
    private var resourceRefresher: ResourceRefresher<DataObject>?
    private var modelInfoSubscription: Disposable?
    private var transformerRegistrar: TransformerRegistrar
    private let onModelInfo = ReplaySubject<DataObject?>()
    private let constantData: [String: DataInput]
    private let queue: TealiumQueue
    /// How long events wait for the first device-names download before getting the fallback model info.
    private let modelInfoTimeoutMs: Int
    static let defaultModelInfoTimeoutMs = 2000
    static let moduleType: String = Modules.Types.deviceData
    var id: String { Self.moduleType }

    private(set) var configuration: DeviceDataModuleConfiguration {
        didSet {
            guard oldValue.deviceNamesUrl != configuration.deviceNamesUrl else { return }
            resourceRefresher = updateResourceRefresher()
        }
    }

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(deviceDataProvider: DeviceDataProvider(),
                  configuration: DeviceDataModuleConfiguration(configuration: moduleConfiguration),
                  networkHelper: context.network.networkHelper,
                  storeProvider: context.moduleStoreProvider,
                  transformerRegistrar: context.transformerRegistrar,
                  queue: context.queue,
                  logger: context.logger)
    }

    init(deviceDataProvider: DeviceDataProvider,
         configuration: DeviceDataModuleConfiguration,
         networkHelper: NetworkHelperProtocol,
         storeProvider: ModuleStoreProvider,
         transformerRegistrar: TransformerRegistrar,
         queue: TealiumQueue,
         logger: LoggerProtocol?,
         modelInfoTimeoutMs: Int = DeviceDataModule.defaultModelInfoTimeoutMs) {
        self.deviceDataProvider = deviceDataProvider
        self.configuration = configuration
        self.networkHelper = networkHelper
        self.dataStore = try? storeProvider.getModuleStore(name: Self.moduleType)
        self.transformerRegistrar = transformerRegistrar
        self.transformerRegistrar.registerTransformation(TransformationSettings(id: "model-info-and-orientation", transformerId: Self.moduleType, scope: .afterCollectors))
        self.queue = queue
        self.logger = logger
        self.modelInfoTimeoutMs = modelInfoTimeoutMs
        self.constantData = deviceDataProvider.getConstantData()
#if os(iOS)
        if configuration.batteryReportingEnabled {
            // Battery monitoring must be enabled on the main queue due to iOS thread safety requirements.
            TealiumQueue.main.ensureOnQueue {
                UIDevice.current.isBatteryMonitoringEnabled = true
            }
        }
#endif
        self.resourceRefresher = updateResourceRefresher()
    }

    @discardableResult
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        self.configuration = DeviceDataModuleConfiguration(configuration: configuration)
        return self
    }

    func shutdown() {
        modelInfoSubscription?.dispose()
        modelInfoSubscription = nil
        // its deinit cancels any in-flight download
        resourceRefresher = nil
    }

    func saveModelInfo(_ modelInfo: DataObject, dataStore: any DataStore) {
        try? dataStore.edit()
            .clear() // to clear the cache of ResourceCacher too
            .putAll(dataObject: modelInfo, expiry: .forever)
            .commit()
    }

    /// The keys `saveModelInfo` writes.
    static let modelInfoKeys = [DeviceDataKey.deviceType, DeviceDataKey.deviceModel, DeviceDataKey.device, DeviceDataKey.modelVariant]

    func readModelInfo(dataStore: any DataStore) -> DataObject? {
        // The same store also caches the downloaded device-names file, so read back only the model keys.
        let stored = dataStore.getAll()
        let modelInfo = DataObject(compacting: Dictionary(uniqueKeysWithValues: Self.modelInfoKeys.map { ($0, stored.getDataItem(key: $0)) }))
        guard modelInfo.count > 0 else {
            return nil
        }
        return modelInfo
    }

    /// Whether real model info was emitted, as opposed to nothing yet or the `nil` fallback.
    private var hasModelInfo: Bool {
        if case .some(.some) = onModelInfo.last() {
            return true
        }
        return false
    }

    func updateResourceRefresher() -> ResourceRefresher<DataObject>? {
        // check that we don't have real model info yet (a fallback can still be replaced)
        guard !hasModelInfo else {
            return nil
        }
        // without datastore emit nil
        guard let dataStore else {
            self.onModelInfo.onNext(nil)
            return nil
        }
        // if we have model info in store, emit that info
        if let cachedModelInfo = readModelInfo(dataStore: dataStore) {
            self.onModelInfo.onNext(cachedModelInfo)
            return nil
        }
        // otherwise try build URL for device-names file, on error emit nil
        guard !configuration.deviceNamesUrl.isEmpty,
              let url = try? configuration.deviceNamesUrl.asUrl() else {
            self.onModelInfo.onNext(nil)
            return nil
        }
        // init refresher (subscribe observers, start refreshing) and return it, or nil if the cached file already had the model info
        return _prepareRefresher(dataStore: dataStore, url: url)
    }

    private func _prepareRefresher(dataStore: any DataStore, url: URL) -> ResourceRefresher<DataObject>? {
        let refresher = ResourceRefresher<DataObject>(networkHelper: networkHelper,
                                                      resourceCacher: ResourceCacher(dataStore: dataStore,
                                                                                     fileName: "device-models"),
                                                      parameters: RefreshParameters(id: "device-models",
                                                                                    url: url,
                                                                                    refreshInterval: 1.days),
                                                      logger: logger)
        modelInfoSubscription?.dispose()
        // emits the cached file first, then every download, until one contains this device
        modelInfoSubscription = refresher.onLatestResource
            .map { [deviceDataProvider] in deviceDataProvider.getModelInfo(from: $0) }
            // with nothing cached, don't hold events on a download that can retry indefinitely
            .merge(Observables.just(DataObject?.none).delay(modelInfoTimeoutMs, on: queue))
            .takeWhile({ $0 == nil }, inclusive: true)
            .subscribe { [weak self] modelData in
                if let modelData {
                    self?.saveModelInfo(modelData, dataStore: dataStore)
                }
                self?.onModelInfo.onNext(modelData)
            }
        refresher.onRefreshError.subscribeOnce { [weak self] _ in
            self?.onModelInfo.onNext(nil)
        }
        // the cached file already had this device, no need to download it again or keep the refresher
        guard !hasModelInfo else {
            return nil
        }
        refresher.requestRefresh()
        return refresher
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        let result = constantData + trackTimeData
        return result.asDataObject()
    }

    private func onMainThreadData() -> Observable<DataObject> {
        guard configuration.batteryReportingEnabled || configuration.screenReportingEnabled else {
            return Observables.just([:])
        }
        return Observables.callback(from: { [deviceDataProvider, configuration] completion in
            dispatchPrecondition(condition: .onQueue(.main))
            var result: DataObject = [:]
            if configuration.batteryReportingEnabled == true {
                result.set(deviceDataProvider.batteryPercent, key: DeviceDataKey.batteryPercent)
                result.set(deviceDataProvider.isCharging, key: DeviceDataKey.isCharging)
            }
            if configuration.screenReportingEnabled == true {
                result += deviceDataProvider.getScreenOrientation()
                result.set(deviceDataProvider.resolution, key: DeviceDataKey.resolution)
                result.set(deviceDataProvider.logicalResolution, key: DeviceDataKey.logicalResolution)
            }
            completion(result)
            return Disposables.disposed()
        }).subscribeOn(.main)
            .observeOn(queue)
    }

    @discardableResult
    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) -> any Disposable {
        let model = DeviceDataProvider.basicModel
        return onModelInfo.asObservable()
            .combineLatest(onMainThreadData())
            .subscribeOnce { deviceModelData, mainThreadData in
                let modelData = deviceModelData ?? [
                    DeviceDataKey.deviceType: model,
                    DeviceDataKey.deviceModel: model,
                    DeviceDataKey.device: model,
                    DeviceDataKey.modelVariant: ""
                ]
                var newDispatch = dispatch
                newDispatch.enrich(data: modelData + mainThreadData)
                completion(newDispatch)
            }
    }

    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: `[String: Any]` of track-time device data.
    var trackTimeData: [String: DataInput] {
        var result = [String: DataInput]()
        result[DeviceDataKey.language] = deviceDataProvider.language
        if configuration.memoryReportingEnabled {
            result += deviceDataProvider.memoryUsage
        }
        return result
    }
}
