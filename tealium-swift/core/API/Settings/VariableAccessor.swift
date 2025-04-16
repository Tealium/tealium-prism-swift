//
//  VariableAccessor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * An object that univocally defines the way to access a variable in the data layer.
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
     * - variable: `someVariable`
     * - path: `[container1, container2]`
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

    public init(variable: String, path: [String]?) {
        self.variable = variable
        self.path = path
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
            return VariableAccessor(variable: variable,
                                    path: object.getArray(key: Keys.path)?.compactMap { $0 })
        }
    }

    static let converter: any DataItemConverter<Self> = Converter()
}
