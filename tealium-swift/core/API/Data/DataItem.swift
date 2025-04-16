//
//  DataItem.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A wrapper class that contains a generic JSON value.
 *
 * You can use the utility getters to obtain the value in the correct type:
 * - You can read any number as Int/Float/Double/NSNumber intercheangebly since it's backed by an NSNumber on disk.
 * - Arrays and Dictionaries will always contain `DataItem` as values and you can use specific getter to get the correct types from them too.
 *
 * - Warning: Do NOT cast this wrapper class to anything else as it will fail. Use the appropriate conversion methods instead.
 *
 * Mistake example:
 * ```
 *  let numbers: [Int?]? = DataItem(value: [1, 2, 3]).getDataArray() as? [Int?] // Cast will fail and numbers will be nil
 *  let numbers: [Int?]? = DataItem(value: [1, 2, 3]).getArray() // This will succeed
 *  let numbers: [Int?]? = DataItem(value: [1, 2, 3]).getDataArray().map { $0.getInt() } // This will also succeed
 *  let numbers: [Int]? = DataItem(value: [1, 2, 3]).getArray().compactMap { $0 } // This will also succeed and remove potentially nil values from the array
 * ```
 */
final public class DataItem {

    /**
     * Initialize this wrapper from a JSON `String` representation of the value.
     *
     * For example:
     * - An `Int` will be represented like this: "1"
     * - A `Bool` will be represented like this: "true"
     * - A `Double` will be represented like this: "2.5"
     * - A `String` will be represented like this: "\"string\""
     * - An `Array` will  be represented like this: "[1,2,3]"
     * - a `Dictionary` will be represented like this: "{\"key\": \"value\"}"
     */
    init(stringValue: String) {
        self.stringValue = stringValue
    }

    /// Initialize a `DataItem` with a specific value that is a valid `DataInput`.
    convenience public init(value: DataInput) {
        self.init(safeValue: value)
    }

    /// - Warning: Only use this method internally to initialize from any other value that was previously parsed by another `DataItem` initializer
    /// as an example in a `DataItem` containing an `Array` or a `Dictionary`, or from a previously encoded value decoded with `AnyDecodable`.
    fileprivate init(safeValue: Any) {
        self.stringValue = nil
        self.value = safeValue
    }

    /// Initialize a `DataItem` with a generic value that can be converted to a valid `Input`.
    convenience public init(converting value: DataInputConvertible) {
        self.init(value: value.toDataInput())
    }

    /**
     * Wrap an `Encodable` or a JSON serializable type of object into a `DataItem` by serializing it.
     *
     * You can safely pass to this method the result of deserializing a JSON object using `JSONSerialization` or any subset of that JSON object.
     * Prefer conforming your types to `DataInputConvertible` rather then `Encodable` for Objects that need to be wrapped into `DataItem` or `DataObject`,
     * and call `DataItem(converting: object)` as that conversion is not failable.
     *
     * Additionally you can pass any valid `DataInput`, including any sort of Dictionary or Array that only contain a mix of valid `DataInput`.
     * Prefer using other methods when dealing with valid `DataInput` whose type are known at compile time (like if you have a `String` or an array of `Int` for example).
     *
     * - Warning: Non conforming floats like `Double.nan` or `Float.infinity` will be silently converted to strings "NaN" and "Infinity" (or "-Infinity" for negative "Infinity") immediately by this function.
     *
     * - throws: An `EncodingError` if any other type of values are passed in the parameter or in eventual nested values.
     */
    public convenience init(serializing value: Any) throws {
        // swiftlint:disable optional_data_string_conversion
        self.init(stringValue: String(decoding: try Tealium.jsonEncoder.encode(AnyCodable(value)), as: UTF8.self)) // Safe as we just used encode that returns UTF8 formatted data
        // swiftlint:enable optional_data_string_conversion
    }

    let stringValue: String?

    lazy private(set) var value: Any? = try? stringValue?.deserialize()

    private var isBool: Bool {
        value is Bool
    }

    private func getNumber<T: DataInput>(as type: T.Type = T.self) -> T? {
        guard !isBool, let number = value as? NSNumber else {
            return nil
        }
        let element: DataInput? = switch T.self {
        case is Int.Type:
            number.intValue
        case is Int64.Type:
            number.int64Value
        case is Float.Type:
            number.floatValue
        case is Double.Type:
            number.doubleValue
        case is Decimal.Type:
            number.decimalValue
        default:
            number
        }
        return element as? T
    }

    /// - returns: The value after having been converted by the `DataItemConverter`.
    public func getConvertible<T>(converter: any DataItemConverter<T>) -> T? {
        converter.convert(dataItem: self)
    }

    /**
     * Returns the data in the requested type if the conversion is possible.
     *
     * Supported types are: 
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * You can call this method without parameters if the return type can be inferred:
     *  ``` swift
     * let dataItem: DataItem = ...
     * let anInt: Int? = dataItem.get()
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataItem: DataItem = ...
     * let anInt = dataItem.get(as: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataItem = DataItem(value: nsNumber)
     * let aDouble: Double? = dataItem.get() // Double(1.5)
     * let anInt: Int? = dataItem.get() // Int(1)
     *  ```
     */
    public func get<T: DataInput>(as type: T.Type = T.self) -> T? {
        let element: DataInput? = switch type {
        case is Int.Type,
            is Int64.Type,
            is Float.Type,
            is Double.Type,
            is Decimal.Type:
            getNumber(as: type)
        default:
            toDataInput()
        }
        return element as? T
    }

    /**
     * Returns the value as an Array of `DataItem` if the underlying value is an Array.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     */
    public func getDataArray() -> [DataItem]? {
        (value as? [Any])?.map { DataItem(safeValue: $0) }
    }

    /**
     * Returns the value as a Dictionary of `DataItem` if the underlying value is a Dictionary.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     */
    public func getDataDictionary() -> [String: DataItem]? {
        (value as? [String: Any])?.mapValues { DataItem(safeValue: $0) }
    }

    /**
     * Returns the value as an `Array` of the (optional) given type.
     *
     * This method will follow the same principles of the `get<T: DataInput>(as:)` counterpart, but applies them on the individual `Array` elements.
     *
     * Supported types are:
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * You can call this method without parameters if the return type can be inferred:
     *  ``` swift
     * let dataItem: DataItem = ...
     * let anIntArray: [Int?]? = dataItem.getArray()
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataItem: DataItem = ...
     * let anIntArray = dataItem.getArray(of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataItem = DataItem(value: [nsNumber])
     * let aDoubleArray = dataItem.getArray(of: Double.self) // [Double(1.5)]
     * let anIntArrat = dataItem.getArray(of: Int.self) // [Int(1)]
     *  ```
     */
    public func getArray<T: DataInput>(of type: T.Type = T.self) -> [T?]? {
        getDataArray()?.map { $0.get(as: type) }
    }

    /**
     * Returns the value as a `Dictionary` of the (optional) given type.
     *
     * This method will follow the same principles of the `get<T: DataInput>(as:)` counterpart, but applies them on the individual `Dictionary` values.
     *
     * Supported types are:
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * You can call this method without parameters if the return type can be inferred:
     *  ``` swift
     * let dataItem: DataItem = ...
     * let anIntDictionary: [Int?]? = dataItem.getDictionary()
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataItem: DataItem = ...
     * let anIntDictionary = dataItem.getDictionary(of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataItem = DataItem(value: ["key": nsNumber])
     * let aDoubleDictionary = dataItem.getDictionary(of: Double.self) // ["key": Double(1.5)]
     * let anIntDictionary = dataItem.getDictionary(of: Int.self) // ["key": Int(1)]
     *  ```
     */
    public func getDictionary<T: DataInput>(of type: T.Type = T.self) -> [String: T?]? {
        getDataDictionary()?.mapValues { $0.get(as: type) }
    }
}

extension DataItem: DataInputConvertible {
    public func toDataInput() -> DataInput {
        if let array = getDataArray() {
            return array.toDataInput()
        } else if let dictionary = getDataDictionary() {
            return dictionary.toDataInput()
        } else {
            return value as? DataInput ?? NSNull()
        }
    }
}

extension DataItem: Decodable {
    convenience public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let anyCodable = try container.decode(AnyCodable.self)
        self.init(safeValue: anyCodable.value)
    }
}
