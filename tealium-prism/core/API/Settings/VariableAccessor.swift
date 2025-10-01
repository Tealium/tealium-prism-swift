//
//  VariableAccessor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * An object that defines the way to access a variable in the data layer.
 *
 * The suggested way to save some constant accessors and reuse them in different part of your application
 * is to define them like so:
 * ```swift
 * extension VariableAccessor {
 *     static let firstLevelKey: VariableAccessor = "some_key"
 *     static let deepKey = VariableAccessor(path: ["container1", "container2"],
 *                                           variable: "some_key")
 * }
 * ```
 *
 * In this way you can create something like a `Condition` or a `Mappings` very easily:
 * ```swift
 * let condition = Condition.isDefined(variable: .deepKey)
 * let mapping = Mappings(key: .firstLevelKey, destination: .deepKey)
 * ```
 */
public struct VariableAccessor {
    enum Keys {
        static let variable = "variable"
        static let path = "path"
    }
    /// The variable name, as found in the data layer.
    let variable: String
    /**
     * The path components, in case the variable is not in the root, with the keys for the object leading up to the variable.
     *
     * For example a `VariableAccessor` with:
     * - path: `[container1, container2]`
     * - variable: `someVariable`
     * Will look for an object in the data layer in the following location:
     *
     * ```json
     * {
     *  "container1": {
     *   "container2": {
     *    "someVariable": "value"
     *  }
     * }
     * ```
     */
    let path: [String]?

    public init(path: [String]? = nil, variable: String) {
        self.path = path
        self.variable = variable
    }
}

extension VariableAccessor: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        DataObject(compacting: [
            Keys.variable: variable,
            Keys.path: path
        ])
    }
}

extension VariableAccessor {
    struct Converter: DataItemConverter {
        typealias Convertible = VariableAccessor
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let variable = object.get(key: Keys.variable, as: String.self) else {
                return nil
            }
            return VariableAccessor(path: object.getArray(key: Keys.path)?.compactMap { $0 },
                                    variable: variable)
        }
    }

    static let converter: any DataItemConverter<Self> = Converter()
}

extension VariableAccessor: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    /// Creates a `VariableAccessor` from a string literal.
    /// The string literal will be used as the variable name with no path.
    /// - Parameter value: The string literal to use as the variable name.
    public init(stringLiteral value: StringLiteralType) {
        self.init(variable: value)
    }
}
