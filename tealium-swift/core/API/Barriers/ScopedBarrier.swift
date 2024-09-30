//
//  ScopedBarrier.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The scope used to define a `ScopedBarrier` in the `CoreSettings`.
public enum BarrierScope: RawRepresentable, Codable, Equatable {
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
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case "all":
            self = .all
        default:
            self = .dispatcher(lowercasedScope)
        }
    }
}

/// A model that defines which scopes a specific barrier, identified by its `barrierId`, should be applied to.
public struct ScopedBarrier: Codable, Equatable {
    let barrierId: String
    let scopes: [BarrierScope]

    func matchesScope(_ scope: BarrierScope) -> Bool {
        self.scopes.contains { $0 == scope }
    }

    public init(barrierId: String, scopes: [BarrierScope]) {
        self.barrierId = barrierId
        self.scopes = scopes
    }

    enum CodingKeys: String, CodingKey {
        case barrierId = "barrier_id"
        case scopes
    }

    public static func == (lhs: ScopedBarrier, rhs: ScopedBarrier) -> Bool {
        lhs.barrierId == rhs.barrierId && lhs.scopes == rhs.scopes
    }
}

extension ScopedBarrier: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        [
            CodingKeys.barrierId.rawValue: barrierId,
            CodingKeys.scopes.rawValue: scopes.map { $0.rawValue }
        ]
    }
}
extension ScopedBarrier {
    struct Converter: DataItemConverter {
        typealias Convertible = ScopedBarrier
        func convert(dataItem: DataItem) -> ScopedBarrier? {
            guard let dictionary = dataItem.getDataDictionary(),
                    let barrierId = dictionary.get(key: CodingKeys.barrierId.rawValue, as: String.self),
                  let scopes = dictionary.getArray(key: CodingKeys.scopes.rawValue, of: String.self)?.compactMap({ $0 }) else {
                return nil
            }
            return ScopedBarrier(barrierId: barrierId, scopes: scopes.map { BarrierScope(rawValue: $0) })
        }
    }
    public static let converter: any DataItemConverter<Self> = Converter()
}
