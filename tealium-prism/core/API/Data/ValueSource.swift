//
//  ValueSource.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

public enum ValueSource: DataInputConvertible {
    case reference(_ ref: ReferenceContainer)
    case constant(_ value: ValueContainer)

    public func toDataInput() -> any DataInput {
        switch self {
        case .reference(let reference):
            reference.toDataInput()
        case .constant(let value):
            value.toDataInput()
        }
    }
}
