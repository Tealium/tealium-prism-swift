//
//  TealiumDataOutput.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A wrapper class that contains a generic JSON value that was read from a DB.
 *
 * You can use the utility getters to obtain the value in the correcty type:
 * - You can read any number as int/doubl/bool intercheangebly since it's backed by an NSNumber on disk
 * - Arrays and Dictionaries will always contain TealiumDataOutput as values and you can use specific getter to get the correct types from them too.
 */
public class TealiumDataOutput {

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init(value: Any) {
        stringValue = nil
        self.value = value
    }

    let stringValue: String?

    lazy private(set) var value: Any? = try? stringValue?.deserialize()

    public func getDataInput() -> TealiumDataInput? {
        if let array = getArray() {
            return array.compactMap { $0.getDataInput() }
        } else if let dictionary = getDictionary() {
            return dictionary.compactMapValues { $0.getDataInput() }
        } else {
            return value as? TealiumDataInput
        }
    }

    public func getNSNumber() -> NSNumber? {
        value as? NSNumber
    }

    public func getInt() -> Int64? {
        getNSNumber()?.int64Value
    }

    public func getDouble() -> Double? {
        getNSNumber()?.doubleValue
    }

    public func getBool() -> Bool? {
        getNSNumber()?.boolValue
    }

    public func getString() -> String? {
        value as? String
    }

    public func getArray() -> [TealiumDataOutput]? {
        (value as? [Any])?.map { TealiumDataOutput(value: $0) }
    }

    public func getDictionary() -> [String: TealiumDataOutput]? {
        (value as? [String: Any])?.mapValues { TealiumDataOutput(value: $0) }
    }
}

public extension Array where Element == TealiumDataOutput {
    func getNSNumber(index: Int) -> NSNumber? {
        self[index].getNSNumber()
    }

    func getInt(index: Int) -> Int64? {
        self[index].getInt()
    }

    func getDouble(index: Int) -> Double? {
        self[index].getDouble()
    }

    func getBool(index: Int) -> Bool? {
        self[index].getBool()
    }

    func getString(index: Int) -> String? {
        self[index].getString()
    }

    func getArray(index: Int) -> [TealiumDataOutput]? {
        self[index].getArray()
    }

    func getDictionary(index: Int) -> [String: TealiumDataOutput]? {
        self[index].getDictionary()
    }
}

public extension Dictionary where Key == String, Value == TealiumDataOutput {
    func getNSNumber(key: String) -> NSNumber? {
        self[key]?.getNSNumber()
    }

    func getInt(key: String) -> Int64? {
        self[key]?.getInt()
    }

    func getDouble(key: String) -> Double? {
        self[key]?.getDouble()
    }

    func getBool(key: String) -> Bool? {
        self[key]?.getBool()
    }

    func getString(key: String) -> String? {
        self[key]?.getString()
    }

    func getArray(key: String) -> [TealiumDataOutput]? {
        self[key]?.getArray()
    }

    func getDictionary(key: String) -> [String: TealiumDataOutput]? {
        self[key]?.getDictionary()
    }
}
