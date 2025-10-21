//
//  ModuleSettings.swift
//  tealium-prism
//
//  Created by Den Guzov on 13/03/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct ModuleSettings {
    enum Keys {
        static let moduleId = "module_id"
        static let moduleType = "module_type"
        static let enabled = "enabled"
        static let rules = "rules"
        static let mappings = "mappings"
        static let configuration = "configuration"
        static let order = "order"
    }
    init(moduleId: String? = nil,
         moduleType: String,
         enabled: Bool? = nil,
         order: Int? = nil,
         rules: Rule<String>? = nil,
         mappings: [MappingOperation]? = nil,
         configuration: DataObject? = nil) {
        self.moduleId = moduleId ?? moduleType
        self.moduleType = moduleType
        self.enabled = enabled ?? true
        self.order = order ?? .max
        self.rules = rules
        self.mappings = mappings
        self.configuration = configuration ?? [:]
    }
    let moduleId: String
    let moduleType: String
    let enabled: Bool
    let order: Int
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
            guard let dataObject = dataItem.getDataDictionary(),
                  let moduleType = dataObject.get(key: Keys.moduleType, as: String.self) else {
                return nil
            }
            let mappings = dataObject.getDataArray(key: Keys.mappings)?
                .compactMap { $0.getConvertible(converter: mappingsConverter) }
            return ModuleSettings(moduleId: dataObject.get(key: Keys.moduleId),
                                  moduleType: moduleType,
                                  enabled: dataObject.get(key: Keys.enabled),
                                  order: dataObject.get(key: Keys.order),
                                  rules: dataObject.getConvertible(key: Keys.rules, converter: ruleConverter),
                                  mappings: mappings,
                                  configuration: dataObject.getDataDictionary(key: Keys.configuration)?.toDataObject())
        }
    }
    static let converter = Converter()
}
