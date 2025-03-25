//
//  ModuleSettings.swift
//  tealium-swift
//
//  Created by Den Guzov on 13/03/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public struct ModuleSettings: Equatable {
    enum Keys {
        static let enabled = "enabled"
        static let applyRules = "apply_rules"
        static let excludeRules = "exclude_rules"
        static let mappings = "mappings"
        static let configuration = "configuration"
    }
    init(enabled: Bool? = nil,
         applyRules: [String]? = nil,
         excludeRules: [String]? = nil,
         mappings: [String: String]? = nil,
         configuration: DataObject = [:]) {
        self.enabled = enabled ?? true
        self.applyRules = applyRules
        self.excludeRules = excludeRules
        self.mappings = mappings
        self.configuration = configuration
    }
    public let enabled: Bool
    public let applyRules: [String]?
    public let excludeRules: [String]?
    public let mappings: [String: String]? // TODO: Change the type
    public let configuration: DataObject
}

extension ModuleSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = ModuleSettings
        func convert(dataItem: DataItem) -> ModuleSettings? {
            guard let moduleDataObject = dataItem.getDataDictionary() else {
                return nil
            }
            return ModuleSettings(enabled: moduleDataObject.get(key: Keys.enabled),
                                  applyRules: moduleDataObject.getArray(key: Keys.applyRules, of: String.self)?.compactMap { $0 },
                                  excludeRules: moduleDataObject.getArray(key: Keys.excludeRules, of: String.self)?.compactMap { $0 },
                                  mappings: moduleDataObject.getDictionary(key: Keys.mappings, of: String.self)?.compactMapValues { $0 },
                                  configuration: DataObject(dictionary: moduleDataObject.getDataDictionary(key: Keys.configuration) ?? [:]))
        }
    }
    public static let converter: any DataItemConverter<Self> = Converter()
}
