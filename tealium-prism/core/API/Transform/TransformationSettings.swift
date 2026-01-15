//
//  TransformationSettings.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Defines the scope where a transformation should be applied.
public enum TransformationScope: RawRepresentable, Codable, Equatable {
    public typealias RawValue = String

    /// Apply transformation after data collection.
    case afterCollectors
    /// Apply transformation to all dispatchers.
    case allDispatchers
    /// Apply transformation to the dispatcher with the given ID.
    case dispatcher(id: String)

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
            self = .dispatcher(id: lowercasedScope)
        }
    }
}

/// Configuration for a data transformation.
public struct TransformationSettings {
    /// Unique identifier for this transformation.
    public let id: String
    /// Identifier of the transformer to use.
    public let transformerId: String
    /// Scopes where this transformation applies.
    public let scopes: [TransformationScope]
    /// Configuration data for the transformer.
    public let configuration: DataObject
    /// Optional conditions for when to apply the transformation.
    public let conditions: Rule<Condition>?
    /**
     * Creates transformation settings with the specified parameters.
     * - Parameters:
     *   - id: Unique identifier for this transformation.
     *   - transformerId: Identifier of the transformer to use.
     *   - scopes: Scopes where this transformation applies.
     *   - configuration: Configuration data for the transformer.
     *   - conditions: Optional conditions for when to apply the transformation.
     */
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

    /**
     * Determines if this transformation applies to the given dispatch scope.
     * - Parameter dispatchScope: The scope to check against.
     * - Returns: `true` if the transformation applies to the scope, `false` otherwise.
     */
    func matchesScope(_ dispatchScope: DispatchScope) -> Bool {
        self.scopes.contains { transformationScope in
            switch (transformationScope, dispatchScope) {
            case (.afterCollectors, .afterCollectors):
                return true
            case (.allDispatchers, .dispatcher):
                return true
            case let (.dispatcher(id: requiredDispatcher), .dispatcher(id: selectedDispatcher)):
                return requiredDispatcher == selectedDispatcher
            default:
                return false
            }
        }
    }

    /**
     * Determines if this transformation should be applied to the given dispatch.
     * - Parameter dispatch: The dispatch to check against.
     * - Returns: `true` if the transformation should be applied, `false` otherwise.
     * - Throws: An error if condition evaluation fails.
     */
    func matchesDispatch(_ dispatch: Dispatch) throws -> Bool {
        guard let conditions else {
            return true
        }
        return try conditions.asMatchable().matches(payload: dispatch.payload)
    }

    /**
     * Creates a composite key combining the transformer ID and transformation ID.
     * - Returns: A string key in the format "transformerId-id".
     */
    func compositeKey() -> String {
        "\(transformerId)-\(id)"
    }

    /// Keys used for data serialization and deserialization.
    enum Keys {
        static let id = "transformation_id"
        static let transformerId = "transformer_id"
        static let scopes = "scopes"
        static let configuration = "configuration"
        static let conditions = "conditions"
    }
}

/// Makes TransformationSettings convertible to DataObject.
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
    /// Converter for creating TransformationSettings from DataItem.
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
    static let converter = Converter()
}
