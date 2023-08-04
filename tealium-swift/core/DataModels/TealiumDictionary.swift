//
//  TealiumDictionary.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias TealiumDictionary = [String: TealiumDataValue]
public typealias TealiumDictionaryOptionals = [String: TealiumDataValue?]

public extension TealiumDictionary {

    init(removingOptionals elements: TealiumDictionaryOptionals ) {
        self.init(uniqueKeysWithValues: elements.compactMap({ key, value in
            guard let value = value else { return nil }
            return (key, value)
        }))
    }

    subscript(removingOptionals key: String) -> TealiumDataValue? {
        get {
            self[key]
        }
        set {
            if let value = newValue {
                self[key] = value
            }
        }
    }
    func asDictionary() -> [String: Any] {
        self
    }
}
