//
//  DataObjectTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

/// These tests are mainly used to showcase how the dictionary input can be used
final class DataObjectTests: XCTestCase {

    func test_init_with_literals() {
        var dataObject: DataObject = [
            "key0": NSNull(),
            "key1": "value1",
            "key2": 2,
            "key3": ["value3"],
            "key4": ["inner4": "value4"],
            "key5": ["inner5": ["deeper5": "value5"]],
            "key6": ["inner6": ["deeper6": ["value6"]]],
            "key7": DataItem(value: ["value7", 7, NSNull()]),
            "key8": DataItem(value: ["inner8": "value8", "otherInner8": 8]),
            "key9": DataItem(value: ["inner9": ["value9", 9]]),
            "key10": DataItem(value: [["value10", 10]]),
        ]
        dataObject.set(["value7", 7, NSNull()], key: "key11")
        dataObject.set(["inner8": "value8", "otherInner8": 8], key: "key12")
        dataObject.set(["inner9": ["value9", 9]], key: "key13")
        dataObject.set([["value10", 10]], key: "key14")
        XCTAssertEqual(dataObject.count, 15)
    }

    func test_init_with_variables_containing_optionals() throws {
        let null: NSNull = NSNull()
        let string: String = "value1"
        let int: Int = 2
        let stringArray: [String?] = ["value3", nil]
        let stringDictionary = ["inner4": Optional("value4"), "otherInner4": nil]
        let nestedDictionary: [String: [String: String?]] = ["inner5": ["deeper5": nil]]
        let nestedDictionaryArray: [String: [String: [String?]]] = ["inner6": ["deeper6": [nil]]]
        let mixedArray: [Any?] = ["value7", nil]
        let mixedDictionary: [String: Any?] = ["inner8": "value8", "otherInner8": nil]
        let nestedMixedDictionary: [String: [Any?]] = ["inner9": ["value9", nil]]
        let nestedMixedArray: [[Any?]] = [["value10", nil]]
        var dataObject: DataObject = [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": stringDictionary,
            "key5": nestedDictionary,
            "key6": nestedDictionaryArray,
            "key7": try DataItem(serializing: mixedArray),
            "key8": try DataItem(serializing: mixedDictionary),
            "key9": try DataItem(serializing: nestedMixedDictionary),
            "key10": try DataItem(serializing: nestedMixedArray),
        ]
        dataObject.set(converting: try DataItem(serializing: mixedArray), key: "key11")
        dataObject.set(converting: try DataItem(serializing: mixedDictionary), key: "key12")
        dataObject.set(converting: try DataItem(serializing: nestedMixedDictionary), key: "key13")
        dataObject.set(converting: try DataItem(serializing: nestedMixedArray), key: "key14")
        XCTAssertEqual(dataObject.count, 15)
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": stringDictionary,
            "key5": nestedDictionary,
            "key6": nestedDictionaryArray,
            "key7": mixedArray,
            "key8": mixedDictionary,
            "key9": nestedMixedDictionary,
            "key10": nestedMixedArray,
            "key11": mixedArray,
            "key12": mixedDictionary,
            "key13": nestedMixedDictionary,
            "key14": nestedMixedArray
        ])
        // Test for NSNull equality since nil and NSNull are equivalent when checked in an NSDictionary.
        XCTAssertNotNil((dataObject.asDictionary()["key3"] as? [Any?])?[1])
        XCTAssertNSNull((dataObject.asDictionary()["key3"] as? [Any?])?[1])
    }

    func test_init_with_variables() throws {
        let null = NSNull()
        let string = "value1"
        let int = 2
        let stringArray = ["value3"]
        let stringDictionary = ["inner4": "value4"]
        let nestedDictionary = ["inner5": ["deeper5": "value5"]]
        let nestedDictionaryArray = ["inner6": ["deeper6": ["value6"]]]
        let mixedArray: [Any] = ["value7", 7]
        let mixedDictionary: [String: Any] = ["inner8": "value8", "otherInner8": 8]
        let nestedMixedDictionary = ["inner9": ["value9", 9]]
        let nestedMixedArray = [["value10", 10]]
        var dataObject: DataObject = [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": stringDictionary,
            "key5": nestedDictionary,
            "key6": nestedDictionaryArray,
            "key7": try DataItem(serializing: mixedArray),
            "key8": try DataItem(serializing: mixedDictionary),
            "key9": try DataItem(serializing: nestedMixedDictionary),
            "key10": try DataItem(serializing: nestedMixedArray),
        ]
        dataObject.set(converting: try DataItem(serializing: mixedArray), key: "key11")
        dataObject.set(converting: try DataItem(serializing: mixedDictionary), key: "key12")
        dataObject.set(converting: try DataItem(serializing: nestedMixedDictionary), key: "key13")
        dataObject.set(converting: try DataItem(serializing: nestedMixedArray), key: "key14")
        XCTAssertEqual(dataObject.count, 15)
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": stringDictionary,
            "key5": nestedDictionary,
            "key6": nestedDictionaryArray,
            "key7": mixedArray,
            "key8": mixedDictionary,
            "key9": nestedMixedDictionary,
            "key10": nestedMixedArray,
            "key11": mixedArray,
            "key12": mixedDictionary,
            "key13": nestedMixedDictionary,
            "key14": nestedMixedArray
        ])
    }

    func test_init_with_optional_variables() throws {
        let null = Optional(NSNull())
        let string = Optional("value1")
        let int = Optional(2)
        let stringArray = Optional(["value3", nil])
        let stringDictionary = Optional(["inner4": "value4", "inner4_nil": nil])
        let nestedDictionary = Optional(["inner5": ["deeper5": "value5"]])
        let nestedDictionaryArray = Optional(["inner6": ["deeper6": ["value6"]]])
        let mixedArray: [Any]? = Optional( ["value7", 7])
        let mixedDictionary: [String: Any]? = Optional( ["inner8": "value8", "otherInner8": 8])
        let nestedMixedDictionary = Optional(["inner9": ["value9", 9]])
        let nestedMixedArray = Optional([["value10", 10]])
        var dataObject: DataObject = [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": stringDictionary,
            "key5": nestedDictionary,
            "key6": nestedDictionaryArray,
            "key7": try DataItem(serializing: mixedArray as Any),
            "key8": try DataItem(serializing: mixedDictionary as Any),
            "key9": try DataItem(serializing: nestedMixedDictionary as Any),
            "key10": try DataItem(serializing: nestedMixedArray as Any),
        ]
        dataObject.set(converting: try DataItem(serializing: mixedArray as Any), key: "key11")
        dataObject.set(converting: try DataItem(serializing: mixedDictionary as Any), key: "key12")
        dataObject.set(converting: try DataItem(serializing: nestedMixedDictionary as Any), key: "key13")
        dataObject.set(converting: try DataItem(serializing: nestedMixedArray as Any), key: "key14")
        XCTAssertEqual(dataObject.count, 15)
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": stringDictionary,
            "key5": nestedDictionary,
            "key6": nestedDictionaryArray,
            "key7": mixedArray,
            "key8": mixedDictionary,
            "key9": nestedMixedDictionary,
            "key10": nestedMixedArray,
            "key11": mixedArray,
            "key12": mixedDictionary,
            "key13": nestedMixedDictionary,
            "key14": nestedMixedArray
        ])
    }

    func test_init_with_duplicate_keys_doesnt_crash_and_uses_second_value() {
        // swiftlint:disable duplicated_key_in_dictionary_literal
        let dataObject: DataObject = [
            "key": "value",
            "key": "otherValue"
        ]
        // swiftlint:enable duplicated_key_in_dictionary_literal
        XCTAssertEqual(dataObject.asDictionary(), ["key": "otherValue"])
    }
}
