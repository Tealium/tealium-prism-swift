//
//  CoreSettings+Converter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 25/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension CoreSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = CoreSettings
        func convert(dataItem: DataItem) -> Convertible? {
            guard let coreDataObject = dataItem.getDataDictionary() else {
                return nil
            }
            return CoreSettings(
                minLogLevel: LogLevel.Minimum(from: coreDataObject.get(key: Keys.minLogLevel)),
                maxQueueSize: coreDataObject.get(key: Keys.maxQueueSize),
                queueExpiration: coreDataObject.get(key: Keys.expirationSeconds, as: Int.self)?.seconds,
                refreshInterval: coreDataObject.get(key: Keys.refreshIntervalSeconds, as: Int.self)?.seconds,
                visitorIdentityKey: coreDataObject.get(key: Keys.visitorIdentityKey)
            )
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
