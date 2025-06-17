//
//  TransformationSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TransformationScope: RawRepresentable, Codable, Equatable {
    public typealias RawValue = String

    case afterCollectors
    case allDispatchers
    case dispatcher(String)

    public var rawValue: String {
        switch self {
        case .afterCollectors:
            return "aftercollectors"
        case .allDispatchers:
            return "alldispatchers"
        case .dispatcher(let dispatcher):
            return dispatcher
        }
    }

    public init(rawValue: String) {
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case "aftercollectors":
            self = .afterCollectors
        case "alldispatchers":
            self = .allDispatchers
        default:
            self = .dispatcher(lowercasedScope)
        }
    }
}

public struct TransformationSettings {
    let id: String
    let transformerId: String
    let scopes: [TransformationScope]
    let configuration: DataObject
    let conditions: Rule<Condition>?
    public init(id: String,
                transformerId: String,
                scopes: [TransformationScope],
                configuration: DataObject = [:],
                conditions: Rule<Condition>? = nil) {
        self.id = id
        self.transformerId = transformerId
        self.scopes = scopes
        self.configuration = configuration
        self.conditions = conditions
    }

    func matchesScope(_ dispatchScope: DispatchScope) -> Bool {
        self.scopes.contains { transformationScope in
            switch (transformationScope, dispatchScope) {
            case (.afterCollectors, .afterCollectors):
                return true
            case (.allDispatchers, .dispatcher):
                return true
            case let (.dispatcher(requiredDispatcher), .dispatcher(selectedDispatcher)):
                return requiredDispatcher == selectedDispatcher
            default:
                return false
            }
        }
    }

    func matchesDispatch(_ dispatch: Dispatch) -> Bool {
        guard let conditions else {
            return true
        }
        return conditions.asMatchable().matches(payload: dispatch.payload)
    }

    enum Keys {
        static let id = "transformation_id"
        static let transformerId = "transformer_id"
        static let scopes = "scopes"
        static let configuration = "configuration"
        static let conditions = "conditions"
    }
}

extension TransformationSettings: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        DataObject(compacting: [
            Keys.id: id,
            Keys.transformerId: transformerId,
            Keys.scopes: scopes.map { $0.rawValue },
            Keys.configuration: configuration,
            Keys.conditions: conditions,
        ])
    }
}

extension TransformationSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = TransformationSettings
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let id = dictionary.get(key: Keys.id, as: String.self),
                  let transformerId = dictionary.get(key: Keys.transformerId, as: String.self),
                  let scopes = dictionary.getArray(key: Keys.scopes, of: String.self)?.compactMap({ $0 }) else {
                return nil
            }
            let configuration = dictionary.getDataDictionary(key: Keys.configuration)?
                .toDataObject() ?? [:]
            let conditions = dictionary.getConvertible(key: Keys.conditions,
                                                       converter: Rule.converter(ruleItemConverter: Condition.converter))
            return TransformationSettings(id: id,
                                          transformerId: transformerId,
                                          scopes: scopes.map { TransformationScope(rawValue: $0) },
                                          configuration: configuration,
                                          conditions: conditions)
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
