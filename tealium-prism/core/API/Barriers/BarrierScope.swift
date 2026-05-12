//
//  BarrierScope.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// The `BarrierScope` defines the available scope that can be assigned to a `Barrier` via a `BarrierSettings`.
///
/// There are only two available scopes that a `Barrier` can impact:
///  - `all`
///  - `dispatchers`
///
/// A `Barrier` scoped to `all` will be checked for its state for every dispatcher before dispatching events to it.
/// A `Barrier` scoped to `dispatchers` will only be checked for its state before dispatching events to
/// the dispatchers identified by the provided `dispatcherIds`.
public enum BarrierScope: Equatable {

    /// Applies to all dispatchers.
    case all
    /// Applies to the dispatchers with the given IDs.
    case dispatchers([String])

    /// Returns `true` if this scope applies to the given dispatcher ID.
    func matches(dispatcherId: String) -> Bool {
        switch self {
        case .all:
            return true
        case .dispatchers(let ids):
            return ids.contains(dispatcherId)
        }
    }
}

extension BarrierScope {
    struct Converter: DataItemConverter {
        typealias Convertible = BarrierScope
        func convert(dataItem: DataItem) -> BarrierScope? {
            if let string: String = dataItem.get() {
                return string.lowercased() == "all" ? .all : nil
            }
            guard let ids = dataItem.getArray(of: String.self)?.compactMap({ $0 }) else {
                return nil
            }
            return .dispatchers(ids)
        }
    }
    static let converter: any DataItemConverter<BarrierScope> = Converter()
}

extension BarrierScope: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        switch self {
        case .all:
            return "all"
        case .dispatchers(let ids):
            return ids as [DataInput]
        }
    }
}
