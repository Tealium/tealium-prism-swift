//
//  DeviceDataCollector.swift
//  tealium-swift
//
//  Created by Den Guzov on 13/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class DeviceDataCollector: Collector, Transformer, BasicModule {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "DeviceData"

    private let deviceDataProvider: DeviceDataProvider
    private let networkHelper: NetworkHelperProtocol
    private let logger: LoggerProtocol?
    private let storeProvider: ModuleStoreProvider
    private var resourceRefresher: ResourceRefresher<DataObject>?
    private var transformerRegistry: TransformerRegistry
    private let onModelInfo = ReplaySubject<DataObject?>()
    private let constantData: [String: DataInput]
    private let queue: TealiumQueue

    private(set) var configuration: DeviceDataConfiguration {
        didSet {
            guard oldValue.deviceNamesUrl != configuration.deviceNamesUrl else { return }
            resourceRefresher = updateResourceRefresher()
        }
    }

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(deviceDataProvider: DeviceDataProvider(),
                  configuration: DeviceDataConfiguration(configuration: moduleConfiguration),
                  networkHelper: context.networkHelper,
                  storeProvider: context.moduleStoreProvider,
                  transformerRegistry: context.transformerRegistry,
                  queue: .worker,
                  logger: context.logger)
    }

    init(deviceDataProvider: DeviceDataProvider,
         configuration: DeviceDataConfiguration,
         networkHelper: NetworkHelperProtocol,
         storeProvider: ModuleStoreProvider,
         transformerRegistry: TransformerRegistry,
         queue: TealiumQueue,
         logger: LoggerProtocol?) {
        self.deviceDataProvider = deviceDataProvider
        self.configuration = configuration
        self.networkHelper = networkHelper
        self.storeProvider = storeProvider
        self.transformerRegistry = transformerRegistry
        self.transformerRegistry.registerTransformation(TransformationSettings(id: "model-info-and-orientation", transformerId: Self.id, scopes: [.afterCollectors]))
        self.queue = queue
        self.logger = logger
        self.constantData = deviceDataProvider.constantData()
        self.resourceRefresher = updateResourceRefresher()
    }

    @discardableResult
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        self.configuration = DeviceDataConfiguration(configuration: configuration)
        return self
    }

    func saveModelInfo(_ modelInfo: DataObject, dataStore: DataStore) {
        try? dataStore.edit()
            .clear() // to clear the cache of ResourceCacher too
            .putAll(dataObject: modelInfo, expiry: .forever)
            .commit()
    }

    func readModelInfo(dataStore: DataStore) -> DataObject? {
        let modelInfo = dataStore.getAll()
        guard modelInfo.count > 0 else {
            return nil
        }
        return modelInfo
    }

    func updateResourceRefresher() -> ResourceRefresher<DataObject>? {
        // check that we don't have model info yet
        guard self.onModelInfo.last() == nil else {
            return nil
        }
        // try get module store, on error publish nil
        guard let dataStore = try? storeProvider.getModuleStore(name: Self.id) else {
            self.onModelInfo.publish(nil)
            return nil
        }
        // if we have model info in store, publish that info
        if let cachedModelInfo = readModelInfo(dataStore: dataStore) {
            self.onModelInfo.publish(cachedModelInfo)
            return nil
        }
        // otherwise try build URL for device-names file, on error publish nil
        guard !configuration.deviceNamesUrl.isEmpty,
              let url = try? configuration.deviceNamesUrl.asUrl() else {
            self.onModelInfo.publish(nil)
            return nil
        }
        // init refresher (subscribe observers, start refreshing) and return it
        return _prepareRefresher(dataStore: dataStore, url: url)
    }

    private func _prepareRefresher(dataStore: DataStore, url: URL) -> ResourceRefresher<DataObject> {
        let refresher = ResourceRefresher<DataObject>(networkHelper: networkHelper,
                                                      resourceCacher: ResourceCacher(dataStore: dataStore,
                                                                                     fileName: "device-models"),
                                                      parameters: RefreshParameters(id: "device-models",
                                                                                    url: url,
                                                                                    refreshInterval: 1.days.seconds()),
                                                      logger: logger)
        refresher.onLatestResource.subscribeOnce { [weak self] resource in
            let modelData = self?.deviceDataProvider.getModelInfo(from: resource)
            if let modelData {
                self?.saveModelInfo(modelData, dataStore: dataStore)
            }
            self?.onModelInfo.publish(modelData)
        }
        refresher.onRefreshError.subscribeOnce { [weak self] _ in
            self?.onModelInfo.publish(nil)
        }
        refresher.requestRefresh()
        return refresher
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        let result = constantData + trackTimeData
        return result.asDataObject()
    }

    private func onScreenOrientation() -> Observable<DataObject> {
        Observable.Callback(from: { [deviceDataProvider] observer in
            deviceDataProvider.getScreenOrientation(completion: observer)
        }).observeOn(queue)
    }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) {
        let model = DeviceDataProvider.basicModel
        onModelInfo.asObservable()
            .combineLatest(onScreenOrientation())
            .subscribeOnce { deviceModelData, orientationData in
                let modelData = deviceModelData ?? [
                    DeviceDataKey.deviceType: model,
                    DeviceDataKey.deviceModel: model,
                    DeviceDataKey.device: model,
                    DeviceDataKey.modelVariant: ""
                ]
                var newDispatch = dispatch
                newDispatch.enrich(data: modelData + orientationData)
                completion(newDispatch)
            }
    }

    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: `[String: Any]` of track-time device data.
    var trackTimeData: [String: DataInput] {
        var result = [String: DataInput]()
        result[DeviceDataKey.batteryPercent] = deviceDataProvider.batteryPercent
        result[DeviceDataKey.isCharging] = deviceDataProvider.isCharging
        result[DeviceDataKey.language] = deviceDataProvider.language
        if configuration.memoryReportingEnabled {
            result += deviceDataProvider.memoryUsage
        }
        return result
    }
}
