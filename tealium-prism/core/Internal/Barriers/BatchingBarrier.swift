//
//  BatchingBarrier.swift
//  tealium-prism
//
//  Created by Denis Guzov on 03/07/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

struct BatchingSettings {
    enum Keys {
        static let batchSize = "batch_size"
    }
    enum Defaults {
        static let batchSize: Int = 1
    }
    let batchSize: Int?

    init(dataObject: DataObject) {
        batchSize = dataObject.get(key: Keys.batchSize)
    }
}

class BatchingBarrier: ConfigurableBarrier {
    static var id: String = "BatchingBarrier"
    private let queueMetrics: QueueMetrics
    private let dispatchers: ObservableState<[Dispatcher]>
    @StateSubject(1)
    private var batchSize: ObservableState<Int?>

    init(queueMetrics: QueueMetrics, dispatchers: ObservableState<[Dispatcher]>, configuration: DataObject) {
        self.queueMetrics = queueMetrics
        self.dispatchers = dispatchers
        _batchSize.value = BatchingSettings(dataObject: configuration).batchSize
    }

    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        let queueSize = queueMetrics.onQueueSizePendingDispatch(for: dispatcherId)
        return batchSizeReached(queueSize, dispatcherId)
            .map { $0 ? .open : .closed }
    }

    private func batchSizeReached(_ queueSize: Observable<Int>, _ dispatcherId: String) -> Observable<Bool> {
        queueSize.combineLatest(dispatcherBatchSize(dispatcherId))
            .map { queueSize, batchSize in
                queueSize >= batchSize
            }.distinct()
    }

    private func dispatcherBatchSize(_ dispatcherId: String) -> Observable<Int> {
        batchSize.combineLatest(dispatchers)
            .map { configuredBatchSize, dispatchers in
                let dispatchLimit = dispatchers.first(where: { $0.id == dispatcherId })?.dispatchLimit
                guard let dispatchLimit else {
                    return BatchingSettings.Defaults.batchSize
                }
                if let configuredBatchSize {
                    return max(min(configuredBatchSize, dispatchLimit), 1)
                }
                return dispatchLimit
            }.distinct()
    }

    func updateConfiguration(_ configuration: DataObject) {
        _batchSize.value = BatchingSettings(dataObject: configuration).batchSize
    }

}

extension BatchingBarrier {
    class Factory: BarrierFactory {
        let _defaultScopes: [BarrierScope]
        init(defaultScopes: [BarrierScope]) {
            _defaultScopes = defaultScopes
        }

        func create(context: TealiumContext, configuration: DataObject) -> BatchingBarrier {
            let dispatchers = context.modulesManager.modules.mapState { modules in
                modules.compactMap { $0 as? Dispatcher }
            }
            return BatchingBarrier(queueMetrics: context.queueMetrics, dispatchers: dispatchers, configuration: configuration)
        }

        func defaultScopes() -> [BarrierScope] {
            _defaultScopes
        }
    }
}
