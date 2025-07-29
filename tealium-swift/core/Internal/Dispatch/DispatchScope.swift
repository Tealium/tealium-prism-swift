//
//  DispatchScope.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum DispatchScope: RawRepresentable, Codable, Equatable {
    public typealias RawValue = String

    case afterCollectors
    case dispatcher(String)

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
            self = .dispatcher(lowercasedScope)
        }
    }
}
