//
//  ValueSource.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Represents the source of a value used in a transformation operation.
///
/// A `ValueSource` can either reference an existing value in the dispatch payload
/// or provide a constant value directly.
public enum ValueSource: DataInputConvertible {
    /// A reference to an existing value in the dispatch payload.
    case reference(_ ref: ReferenceContainer)
    /// A constant value to be used directly.
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
