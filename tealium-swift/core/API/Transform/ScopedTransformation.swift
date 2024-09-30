//
//  ScopedTransformation.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TransformationScope: RawRepresentable, Codable, Equatable {
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

    public init(rawValue: String) {
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

public struct ScopedTransformation: Codable, Equatable {
    let id: String
    let transformerId: String
    let scopes: [TransformationScope]
    public init(id: String, transformerId: String, scopes: [TransformationScope]) {
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

    public static func == (lhs: ScopedTransformation, rhs: ScopedTransformation) -> Bool {
        return lhs.id == rhs.id && lhs.transformerId == rhs.transformerId && lhs.scopes == rhs.scopes
    }
}

extension ScopedTransformation: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        [
            CodingKeys.id.rawValue: id,
            CodingKeys.transformerId.rawValue: transformerId,
            CodingKeys.scopes.rawValue: scopes.map { $0.rawValue }
        ]
    }
}

extension ScopedTransformation {
    struct Converter: DataItemConverter {
        typealias Convertible = ScopedTransformation
        func convert(dataItem: DataItem) -> ScopedTransformation? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let id = dictionary.get(key: CodingKeys.id.rawValue, as: String.self),
                  let transformerId = dictionary.get(key: CodingKeys.transformerId.rawValue, as: String.self),
                  let scopes = dictionary.getArray(key: CodingKeys.scopes.rawValue, of: String.self)?.compactMap({ $0 }) else {
                return nil
            }
            return ScopedTransformation(id: id, transformerId: transformerId, scopes: scopes.map { TransformationScope(rawValue: $0) })
        }
    }
    public static let converter: any DataItemConverter<Self> = Converter()
}
