//
//  ScopedBarrier.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The scope used to define a `ScopedBarrier` in the `CoreSettings`.
public enum BarrierScope: RawRepresentable, Equatable {
    public typealias RawValue = String

    case all
    case dispatcher(String)

    public var rawValue: String {
        switch self {
        case .all:
            return "all"
        case .dispatcher(let dispatcher):
            return dispatcher
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "all":
            self = .all
        default:
            self = .dispatcher(rawValue)
        }
    }
}

extension BarrierScope: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        self.rawValue
    }
}

/// A model that defines which scopes a specific barrier, identified by its `barrierId`, should be applied to.
public struct ScopedBarrier: Equatable {
    let barrierId: String
    let scopes: [BarrierScope]

    func matchesScope(_ scope: BarrierScope) -> Bool {
        self.scopes.contains { $0 == scope }
    }

    public init(barrierId: String, scopes: [BarrierScope]) {
        self.barrierId = barrierId
        self.scopes = scopes
    }

    enum Keys {
        static let barrierId = "barrier_id"
        static let scopes = "scopes"
    }

    public static func == (lhs: ScopedBarrier, rhs: ScopedBarrier) -> Bool {
        lhs.barrierId == rhs.barrierId && lhs.scopes == rhs.scopes
    }
}

extension ScopedBarrier: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        [
            Keys.barrierId: barrierId,
            Keys.scopes: scopes
        ]
    }
}
extension ScopedBarrier {
    struct Converter: DataItemConverter {
        typealias Convertible = ScopedBarrier
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                    let barrierId = dictionary.get(key: Keys.barrierId, as: String.self),
                  let scopes = dictionary.getArray(key: Keys.scopes, of: String.self)?.compactMap({ $0 }) else {
                return nil
            }
            return ScopedBarrier(barrierId: barrierId, scopes: scopes.map { BarrierScope(rawValue: $0) })
        }
    }
    public static let converter: any DataItemConverter<Self> = Converter()
}
