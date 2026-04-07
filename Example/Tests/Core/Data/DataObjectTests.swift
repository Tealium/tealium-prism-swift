//
//  DataObjectTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
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
            "key3": try DataItem(serializing: stringArray),
            "key4": try DataItem(serializing: stringDictionary),
            "key5": try DataItem(serializing: nestedDictionary),
            "key6": try DataItem(serializing: nestedDictionaryArray),
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

    func test_init_with_array_with_optional_elements() throws {
        let stringArray = ["value0", nil]
        let intArray = [1, nil]
        let int64Array = [Int64(2), nil]
        let floatArray = [Float(3.0), nil]
        let doubleArray = [Double(4.0), nil]
        let nsNumberArray = [NSNumber(5), nil]
        let decimalArray = [Decimal(6), nil]
        let boolArray = [true, nil]
        let dataInputArray: [DataInput?] = ["abc", 123, nil]
        let nestedInputArray: [[DataInput]?] = [["abc"], nil]
        let nestedInputDict: [[String: DataInput]?] = [["key10": "abc", "int": 123], nil]
        let dataObject: DataObject = [
            "key0": stringArray.asDataArray(),
            "key1": intArray.asDataArray(),
            "key2": int64Array.asDataArray(),
            "key3": floatArray.asDataArray(),
            "key4": doubleArray.asDataArray(),
            "key5": nsNumberArray.asDataArray(),
            "key6": decimalArray.asDataArray(),
            "key7": boolArray.asDataArray(),
            "key8": dataInputArray.asDataArray(),
            "key9": nestedInputArray.asDataArray(),
            "key10": nestedInputDict.asDataArray()
        ]
        XCTAssertEqual(dataObject.count, 11)
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": ["value0", NSNull()],
            "key1": [1, NSNull()],
            "key2": [Int64(2), NSNull()],
            "key3": [Float(3.0), NSNull()],
            "key4": [Double(4.0), NSNull()],
            "key5": [NSNumber(5), NSNull()],
            "key6": [Decimal(6), NSNull()],
            "key7": [true, NSNull()],
            "key8": ["abc", 123, NSNull()],
            "key9": [["abc"], NSNull()],
            "key10": [["key10": "abc", "int": 123], NSNull()]
        ])
    }

    func test_init_with_dictionary_with_optional_elements() throws {
        let stringDict = ["key0": "value0", "nil": nil]
        let intDict = ["key1": 1, "nil": nil]
        let int64Dict = ["key2": Int64(2), "nil": nil]
        let floatDict = ["key3": Float(3.0), "nil": nil]
        let doubleDict = ["key4": Double(4.0), "nil": nil]
        let nsNumberDict = ["key5": NSNumber(5), "nil": nil]
        let decimalDict = ["key6": Decimal(6), "nil": nil]
        let boolDict = ["key7": true, "nil": nil]
        let dataInputDict: [String: DataInput?] = ["key8": "abc", "int": 123, "nil": nil]
        let nestedInputDict: [String: [String: DataInput]?] = ["key9": ["key9": "abc", "int": 123], "nil": nil]
        let nestedInputArray: [String: [DataInput]?] = ["key10": ["abc", 123], "nil": nil]
        let dataObject: DataObject = [
            "key0": stringDict.asDataDictionary(),
            "key1": intDict.asDataDictionary(),
            "key2": int64Dict.asDataDictionary(),
            "key3": floatDict.asDataDictionary(),
            "key4": doubleDict.asDataDictionary(),
            "key5": nsNumberDict.asDataDictionary(),
            "key6": decimalDict.asDataDictionary(),
            "key7": boolDict.asDataDictionary(),
            "key8": dataInputDict.asDataDictionary(),
            "key9": nestedInputDict.asDataDictionary(),
            "key10": nestedInputArray.asDataDictionary()
        ]
        XCTAssertEqual(dataObject.count, 11)
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": ["key0": "value0", "nil": NSNull()],
            "key1": ["key1": 1, "nil": NSNull()],
            "key2": ["key2": Int64(2), "nil": NSNull()],
            "key3": ["key3": Float(3.0), "nil": NSNull()],
            "key4": ["key4": Double(4.0), "nil": NSNull()],
            "key5": ["key5": NSNumber(5), "nil": NSNull()],
            "key6": ["key6": Decimal(6), "nil": NSNull()],
            "key7": ["key7": true, "nil": NSNull()],
            "key8": ["key8": "abc", "int": 123, "nil": NSNull()],
            "key9": ["key9": ["key9": "abc", "int": 123], "nil": NSNull()],
            "key10": ["key10": ["abc", 123], "nil": NSNull()]

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
        let actualNil = Optional<Int>.none
        var dataObject: DataObject = [
            "key0": try DataItem(serializing: null as Any),
            "key1": try DataItem(serializing: string as Any),
            "key2": try DataItem(serializing: int as Any),
            "key3": try DataItem(serializing: stringArray as Any),
            "key4": try DataItem(serializing: stringDictionary as Any),
            "key5": try DataItem(serializing: nestedDictionary as Any),
            "key6": try DataItem(serializing: nestedDictionaryArray as Any),
            "key7": try DataItem(serializing: mixedArray as Any),
            "key8": try DataItem(serializing: mixedDictionary as Any),
            "key9": try DataItem(serializing: nestedMixedDictionary as Any),
            "key10": try DataItem(serializing: nestedMixedArray as Any),
            "key15": try DataItem(serializing: actualNil as Any)
        ]
        dataObject.set(converting: try DataItem(serializing: mixedArray as Any), key: "key11")
        dataObject.set(converting: try DataItem(serializing: mixedDictionary as Any), key: "key12")
        dataObject.set(converting: try DataItem(serializing: nestedMixedDictionary as Any), key: "key13")
        dataObject.set(converting: try DataItem(serializing: nestedMixedArray as Any), key: "key14")
        XCTAssertEqual(dataObject.count, 16)
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
            "key14": nestedMixedArray,
            "key15": NSNull()
        ])
    }

    func test_init_compacting_optional_variables() throws {
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
        let actualNil = Optional<Int>.none
        var dataObject = DataObject(compacting: [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray?.asDataArray(),
            "key4": stringDictionary?.asDataDictionary(),
            "key5": nestedDictionary,
            "key6": try nestedDictionaryArray.flatMap { try DataItem(serializing: $0) },
            "key7": try mixedArray.flatMap { try DataItem(serializing: $0) },
            "key8": try mixedDictionary.flatMap { try DataItem(serializing: $0) },
            "key9": try nestedMixedDictionary.flatMap { try DataItem(serializing: $0 ) },
            "key10": try nestedMixedArray.flatMap { try DataItem(serializing: $0) },
            "key15": actualNil
        ])
        dataObject.set(converting: try DataItem(serializing: mixedArray as Any), key: "key11")
        dataObject.set(converting: try DataItem(serializing: mixedDictionary as Any), key: "key12")
        dataObject.set(converting: try DataItem(serializing: nestedMixedDictionary as Any), key: "key13")
        dataObject.set(converting: try DataItem(serializing: nestedMixedArray as Any), key: "key14")
        XCTAssertEqual(dataObject.count, 15, "actualNil should be removed")
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": null,
            "key1": string,
            "key2": int,
            "key3": stringArray,
            "key4": ["inner4": "value4", "inner4_nil": NSNull()],
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

    func test_init_not_adding_only_some_optional_variables() throws {
        let null = Optional(NSNull())
        let string = Optional("value1")
        let bool = Optional(true)
        let actualNil = Optional<Int>.none
        var dataObject: DataObject = [
            "key0": null.asDataItem(), // This would use `null` as a default value if the value was nil
            "key1": string.asDataItem() // This would use `null` as a default value if the value was nil
        ]
        if let bool {
            dataObject.set(bool, key: "key2") // Will enter here because bool is not nil
        }
        if let actualNil {
            dataObject.set(actualNil, key: "key3") // Will never go in here because actualNil is nil
        }
        XCTAssertEqual(dataObject.count, 3, "actualNil should not be inserted")
        XCTAssertFalse(dataObject.keys.contains("key3"))
        XCTAssertEqual(dataObject.asDictionary(), [
            "key0": null,
            "key1": string,
            "key2": bool
        ])
    }

    func test_init_with_duplicate_keys_doesnt_crash_and_uses_second_value() {
        let dataObject: DataObject = [
            "key": "value",
            "key": "otherValue" // swiftlint:disable:this duplicated_key_in_dictionary_literal
        ]
        XCTAssertEqual(dataObject.asDictionary(), ["key": "otherValue"])
    }

    func test_init_with_jsonString_parses_dictionary() throws {
        let dataObject = try DataObject(jsonString: "{\"key1\": \"value1\", \"key2\": 2}")
        XCTAssertEqual(dataObject.get(key: "key1"), "value1")
        XCTAssertEqual(dataObject.get(key: "key2"), 2)
    }

    func test_init_with_jsonString_throws_jsonIsNotADictionary_when_json_is_not_a_dictionary() {
        XCTAssertThrows(try DataObject(jsonString: "[\"value1\", \"value2\"]")) { (error: JSONParsingError) in
            guard case .jsonIsNotADictionary = error else {
                XCTFail("Expected ParsingError.jsonIsNotADictionary, got \(error)")
                return
            }
        }
    }

    func test_init_with_jsonString_throws_invalidJSON_when_string_is_not_valid_json() {
        XCTAssertThrows(try DataObject(jsonString: "not json")) { (error: JSONParsingError) in
            guard case .invalidJSON = error else {
                XCTFail("Expected ParsingError.invalidJSON, got \(error)")
                return
            }
        }
    }

    func test_buildPath_creates_missing_components() {
        var dataObject: DataObject = [:]
        dataObject.buildPath(JSONPath["container"][0]["property"], andSet: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": [["property": "value"]]])
    }

    func test_buildPath_fills_arrays_with_nils() throws {
        var dataObject: DataObject = [:]
        dataObject.buildPath(JSONPath["container"][3]["property"], andSet: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": try DataItem(serializing: [nil, nil, nil, ["property": "value"]])])
    }

    func test_buildPath_merges_objects() {
        var dataObject: DataObject = [
            "container": [
                "array": ["1", "2", "3"]
            ]
        ]
        dataObject.buildPath(JSONPath["container"]["property"], andSet: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": DataItem(value: [
            "property": "value",
            "array": ["1", "2", "3"]
        ])])
    }

    func test_buildPath_merges_arrays() throws {
        var dataObject: DataObject = [
            "container": [
                "array": ["1", "2", "3"]
            ]
        ]
        dataObject.buildPath(JSONPath["container"]["array"][5], andSet: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": [
            "array": try DataItem(serializing: ["1", "2", "3", nil, nil, "value"])
        ]])
    }

    func test_buildPath_replaces_arrays_with_objects_if_path_requires_object() {
        var dataObject: DataObject = [
            "container": [
                "array": ["1", "2", "3"]
            ]
        ]
        dataObject.buildPath(JSONPath["container"]["array"]["property"], andSet: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": [
            "array": ["property": "value"]
        ]])
    }

    func test_buildPath_replaces_objects_with_arrays_if_path_requires_array() {
        var dataObject: DataObject = [
            "container": [
                "array": ["1", "2", "3"]
            ]
        ]
        dataObject.buildPath(JSONPath["container"][0]["property"], andSet: DataItem(value: "value"))
        XCTAssertEqual(dataObject, ["container": [["property": "value"]]])
    }
}
