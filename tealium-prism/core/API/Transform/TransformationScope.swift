//
//  TransformationScope.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// Defines the scope where a transformation should be applied.
public enum TransformationScope: Equatable, DataInputConvertible {
    /// Apply transformation after data collection.
    case afterCollectors
    /// Apply transformation to all dispatchers.
    case allDispatchers
    /// Apply transformation to the dispatchers with the given IDs.
    case dispatchers([String])

    public func toDataInput() -> any DataInput {
        switch self {
        case .afterCollectors:
            "aftercollectors"
        case .allDispatchers:
            "alldispatchers"
        case .dispatchers(let ids):
            ids as [DataInput]
        }
    }
}

extension TransformationScope {
    struct Converter: DataItemConverter {
        typealias Convertible = TransformationScope
        func convert(dataItem: DataItem) -> Convertible? {
            if let string: String = dataItem.get() {
                switch string.lowercased() {
                case "aftercollectors": return .afterCollectors
                case "alldispatchers": return .allDispatchers
                default: return nil
                }
            }
            guard let ids = dataItem.getArray(of: String.self)?.compactMap({ $0 }) else {
                return nil
            }
            return .dispatchers(ids)
        }
    }
    static let converter: any DataItemConverter<TransformationScope> = Converter()
}
