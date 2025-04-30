//
//  BarrierScope.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// The scope used to define a `BarrierSettings` in the `SDKSettings`.
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
