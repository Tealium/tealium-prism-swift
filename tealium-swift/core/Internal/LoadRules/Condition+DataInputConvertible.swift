//
//  Condition+DataInputConvertible.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

struct AlwaysFalse: Matchable {
    func matches(payload: DataObject) -> Bool {
        false
    }
}

struct AlwaysTrue: Matchable {
    func matches(payload: DataObject) -> Bool {
        true
    }
}

extension Condition: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        DataObject(compacting: [
            Condition.Keys.path: path,
            Condition.Keys.variable: variable,
            Condition.Keys.operator: self.operator.rawValue,
            Condition.Keys.filter: filter,
        ])
    }
}
