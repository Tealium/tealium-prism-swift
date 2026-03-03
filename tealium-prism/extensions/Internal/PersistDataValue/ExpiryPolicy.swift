//
//  ExpiryPolicy.swift
//  tealium-prism
//
//  Created by Den Guzov on 20/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

/// Defines the expiry policy for persisted data values.
/// Unlike `Expiry`, which may hold an absolute date, `ExpiryPolicy` always
/// produces a fresh `Expiry` via `resolve()` at persistence time.
public enum ExpiryPolicy: Equatable {
    /// Expires when the session ends.
    case session
    /// Expires when the app restarts.
    case untilRestart
    /// Never expires.
    case forever
    /// Expires after the specified duration from the moment of persistence.
    case duration(TimeFrame)

    func resolve() -> Expiry {
        switch self {
        case .session: return .session
        case .untilRestart: return .untilRestart
        case .forever: return .forever
        case .duration(let timeFrame): return .afterCustom(timeFrame: timeFrame)
        }
    }
}

extension ExpiryPolicy: DataInputConvertible {
    public func toDataInput() -> DataInput {
        switch self {
        case .session: return Int64(-2)
        case .forever: return Int64(-1)
        case .untilRestart: return Int64(-3)
        case .duration(let timeFrame): return Int64(timeFrame.inSeconds())
        }
    }

    struct Converter: DataItemConverter {
        typealias Convertible = ExpiryPolicy
        func convert(dataItem: DataItem) -> ExpiryPolicy? {
            guard let value = dataItem.get(as: Int64.self) else {
                return nil
            }
            switch value {
            case -1: return .forever
            case -2: return .session
            case -3: return .untilRestart
            case let value where value >= 0: return .duration(TimeFrame(unit: .seconds, interval: value))
            default: return nil
            }
        }
    }

    static let converter = Converter()
}
