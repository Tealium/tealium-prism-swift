//
//  ScopedTransformation.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TransformationScope: RawRepresentable, Codable {
    public typealias RawValue = String

    case afterCollectors
    case allDispatchers
    case dispatcher(String)

    public var rawValue: String {
        switch self {
        case .afterCollectors:
            return "aftercollectors"
        case .allDispatchers:
            return "alldispatchers"
        case .dispatcher(let dispatcher):
            return dispatcher
        }
    }

    public init?(rawValue: String) {
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case "aftercollectors":
            self = .afterCollectors
        case "alldispatchers":
            self = .allDispatchers
        default:
            self = .dispatcher(lowercasedScope)
        }
    }
}

public struct ScopedTransformation: Codable {
    let id: String
    let transformerId: String
    let scopes: [TransformationScope]

    init?(from dictionary: [String: Any]) {
        guard let id = dictionary[CodingKeys.id.rawValue] as? String,
              let transformerId = dictionary[CodingKeys.transformerId.rawValue] as? String,
              let scopes = dictionary[CodingKeys.scopes.rawValue] as? [String] else {
            return nil
        }
        self.init(id: id, transformerId: transformerId, scopes: scopes.compactMap { TransformationScope(rawValue: $0) })
    }

    init(id: String, transformerId: String, scopes: [TransformationScope]) {
        self.id = id
        self.transformerId = transformerId
        self.scopes = scopes
    }

    func matchesScope(_ dispatchScope: DispatchScope) -> Bool {
        self.scopes.contains { transformationScope in
            switch (transformationScope, dispatchScope) {
            case (.afterCollectors, .afterCollectors):
                return true
            case (.allDispatchers, .dispatcher):
                return true
            case let (.dispatcher(requiredDispatcher), .dispatcher(selectedDispatcher)):
                return requiredDispatcher == selectedDispatcher
            default:
                return false
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "transformation_id"
        case transformerId = "transformer_id"
        case scopes
    }
}
