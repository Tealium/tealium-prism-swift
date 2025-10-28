//
//  BarrierScope.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// The `BarrierScope` defines the available scopes that can be assigned to a `Barrier` via a `BarrierSettings`.
///
/// There are only two available scopes that a `Barrier` can impact:
///  - `all`
///  - `dispatcher`
///
/// A `Barrier` scoped to `all` will be checked for its state for every dispatcher before dispatching events to it.
/// A `Barrier` scoped to `dispatcher` will only be checked for its state for the specific dispatcher as identified by the given dispatcher name.
public enum BarrierScope: RawRepresentable, Equatable {
    public typealias RawValue = String

    /// Applies to all dispatchers.
    case all
    /// Applies to the dispatcher with the given ID.
    case dispatcher(id: String)

    public var rawValue: String {
        switch self {
        case .all:
            return "all"
        case .dispatcher(let dispatcher):
            return dispatcher
        }
    }

    public init(rawValue: String) {
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case "all":
            self = .all
        default:
            self = .dispatcher(id: rawValue)
        }
    }
}

extension BarrierScope: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        self.rawValue
    }
}
