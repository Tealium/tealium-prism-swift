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
    let scope: [TransformationScope]

    func matchesScope(_ dispatchScope: DispatchScope) -> Bool {
        self.scope.contains { transformationScope in
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
}
