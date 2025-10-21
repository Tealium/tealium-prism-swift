//
//  ConsentSettings.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct ConsentSettings {
    let configurations: [String: ConsentConfiguration]
    enum Keys {
        static let configurations = "configurations"
    }

    init(settings: DataObject) {
        self.init(configurations: settings.getDataDictionary(key: Keys.configurations)?
            .compactMapValues { $0.getConvertible(converter: ConsentConfiguration.converter) } ?? [:])
    }

    init(configurations: [String: ConsentConfiguration]) {
        self.configurations = configurations
    }
}

extension ConsentSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = ConsentSettings
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dataObject = dataItem.getDataDictionary()?.toDataObject() else {
                return nil
            }
            return ConsentSettings(settings: dataObject)
        }
    }
    static let converter = Converter()
}
