//
//  ScopedBarrier.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The scope used to define a `ScopedBarrier` in the `CoreSettings`.
public enum BarrierScope: RawRepresentable, Codable {
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
public struct ScopedBarrier: Codable {
    let barrierId: String
    let scopes: [BarrierScope]

    func matchesScope(_ scope: BarrierScope) -> Bool {
        self.scopes.contains { $0 == scope }
    }

    public init(barrierId: String, scopes: [BarrierScope]) {
        self.barrierId = barrierId
        self.scopes = scopes
    }

    init?(from dictionary: [String: Any]) {
        guard let barrierId = dictionary[CodingKeys.barrierId.rawValue] as? String,
              let scopes = dictionary[CodingKeys.scopes.rawValue] as? [String] else {
            return nil
        }
        self.init(barrierId: barrierId, scopes: scopes.map { BarrierScope(rawValue: $0) })
    }

    enum CodingKeys: String, CodingKey {
        case barrierId = "barrier_id"
        case scopes
    }
}
