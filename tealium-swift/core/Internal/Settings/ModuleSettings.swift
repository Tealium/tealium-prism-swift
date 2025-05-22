//
//  ModuleSettings.swift
//  tealium-swift
//
//  Created by Den Guzov on 13/03/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct ModuleSettings {
    enum Keys {
        static let enabled = "enabled"
        static let rules = "rules"
        static let mappings = "mappings"
        static let configuration = "configuration"
    }
    init(enabled: Bool? = nil,
         rules: Rule<String>? = nil,
         mappings: [MappingOperation]? = nil,
         configuration: DataObject? = nil) {
        self.enabled = enabled ?? true
        self.rules = rules
        self.mappings = mappings
        self.configuration = configuration ?? [:]
    }
    let enabled: Bool
    let rules: Rule<String>?
    let mappings: [MappingOperation]?
    let configuration: DataObject
}

extension ModuleSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = ModuleSettings
        let ruleConverter = Rule.converter(ruleItemConverter: String.converter)
        let mappingsConverter = MappingOperation
            .converter(parametersConverter: MappingParameters.converter)
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dataObject = dataItem.getDataDictionary() else {
                return nil
            }
            let mappings = dataObject.getDataArray(key: Keys.mappings)?
                .compactMap { $0.getConvertible(converter: mappingsConverter) }
            return ModuleSettings(enabled: dataObject.get(key: Keys.enabled),
                                  rules: dataObject.getConvertible(key: Keys.rules, converter: ruleConverter),
                                  mappings: mappings,
                                  configuration: dataObject.getDataDictionary(key: Keys.configuration)?.toDataObject())
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
