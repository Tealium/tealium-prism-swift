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
         mappings: [String: String]? = nil,
         configuration: DataObject = [:]) {
        self.enabled = enabled ?? true
        self.rules = rules
        self.mappings = mappings
        self.configuration = configuration
    }
    let enabled: Bool
    let rules: Rule<String>?
    let mappings: [String: String]? // TODO: Change the type
    let configuration: DataObject
}

extension ModuleSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = ModuleSettings
        let ruleConverter = Rule.converter(ruleItemConverter: String.converter)
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dataObject = dataItem.getDataDictionary() else {
                return nil
            }
            return ModuleSettings(enabled: dataObject.get(key: Keys.enabled),
                                  rules: dataObject.getConvertible(key: Keys.rules, converter: ruleConverter),
                                  mappings: dataObject.getDictionary(key: Keys.mappings, of: String.self)?.compactMapValues { $0 },
                                  configuration: DataObject(dictionary: dataObject.getDataDictionary(key: Keys.configuration) ?? [:]))
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
