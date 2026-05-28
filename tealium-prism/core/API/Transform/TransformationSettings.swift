//
//  TransformationSettings.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Configuration for a data transformation.
public struct TransformationSettings {
    /// Unique identifier for this transformation.
    public let id: String
    /// Identifier of the transformer to use.
    public let transformerId: String
    /// Scope where this transformation applies.
    public let scope: TransformationScope
    /// Configuration data for the transformer.
    public let configuration: DataObject
    /// Optional conditions for when to apply the transformation.
    public let conditions: Rule<Condition>?
    /// Execution order. Lower values run first; defaults to `Int.max` when unspecified.
    public let order: Int
    /**
     * Creates transformation settings with the specified parameters.
     * - Parameters:
     *   - id: Unique identifier for this transformation.
     *   - transformerId: Identifier of the transformer to use.
     *   - scope: Scope where this transformation applies.
     *   - configuration: Configuration data for the transformer.
     *   - conditions: Optional conditions for when to apply the transformation.
     *   - order: Execution order. Lower values run first; defaults to `Int.max` when unspecified.
     */
    public init(id: String,
                transformerId: String,
                scope: TransformationScope,
                configuration: DataObject = [:],
                conditions: Rule<Condition>? = nil,
                order: Int? = nil) {
        self.id = id
        self.transformerId = transformerId
        self.scope = scope
        self.configuration = configuration
        self.conditions = conditions
        self.order = order ?? Int.max
    }

    /**
     * Determines if this transformation applies to the given dispatch scope.
     * - Parameter dispatchScope: The scope to check against.
     * - Returns: `true` if the transformation applies to the scope, `false` otherwise.
     */
    func matchesScope(_ dispatchScope: DispatchScope) -> Bool {
        switch (scope, dispatchScope) {
        case (.afterCollectors, .afterCollectors):
            return true
        case (.allDispatchers, .dispatcher):
            return true
        case let (.dispatchers(ids), .dispatcher(id: selectedDispatcher)):
            return ids.contains(selectedDispatcher)
        default:
            return false
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
        static let scope = "scope"
        static let configuration = "configuration"
        static let conditions = "conditions"
        static let order = "order"
    }
}

extension TransformationSettings {
    /// Converter for creating TransformationSettings from DataItem.
    struct Converter: DataItemConverter {
        typealias Convertible = TransformationSettings
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let id: String = dictionary.get(key: Keys.id),
                  let transformerId: String = dictionary.get(key: Keys.transformerId),
                  let scope = dictionary.getConvertible(key: Keys.scope, converter: TransformationScope.converter) else {
                return nil
            }
            let configuration = dictionary.getDataDictionary(key: Keys.configuration)?
                .toDataObject() ?? [:]
            let conditions = dictionary.getConvertible(key: Keys.conditions,
                                                       converter: Rule.converter(ruleItemConverter: Condition.converter))
            let order: Int? = dictionary.get(key: Keys.order)
            return TransformationSettings(id: id,
                                          transformerId: transformerId,
                                          scope: scope,
                                          configuration: configuration,
                                          conditions: conditions,
                                          order: order)
        }
    }
    static let converter: any DataItemConverter<TransformationSettings> = Converter()
}
