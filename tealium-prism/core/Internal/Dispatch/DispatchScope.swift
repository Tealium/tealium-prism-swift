//
//  DispatchScope.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Defines the positions during event processing that can be extended.
public enum DispatchScope: RawRepresentable, Codable, Equatable {
    public typealias RawValue = String

    /// This scope happens after data has been collected by any `Collector` implementations in
    /// the system; it is also prior to being stored on disk.
    case afterCollectors
    /// This scope happens when the `Dispatch` is being sent to the given `Dispatcher`.
    case dispatcher(id: String)

    public var rawValue: String {
        switch self {
        case .afterCollectors:
            "aftercollectors"
        case .dispatcher(let dispatcher):
            dispatcher
        }
    }

    public init?(rawValue: String) {
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case DispatchScope.afterCollectors.rawValue:
            self = .afterCollectors
        default:
            self = .dispatcher(id: lowercasedScope)
        }
    }
}
