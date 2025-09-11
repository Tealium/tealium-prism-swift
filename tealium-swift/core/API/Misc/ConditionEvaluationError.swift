//
//  ConditionEvaluationError.swift
//  tealium-swift-Core-iOS
//
//  Created by Den Guzov on 28/08/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Error to signify that matching a `Condition` has failed in an exceptional way during evaluation.
/// It is therefore unable to return an accurate result.
public struct ConditionEvaluationError: Error, InvalidMatchError {
    public enum ErrorType: TealiumErrorEnum {
        /// There is no data item defined for the specified key.
        case missingDataItem
        /// Filter was not defined, bit it's required for the operation.
        case missingFilter
        /// Either data item or filter cannot be parsed as a number for numerical match operation.
        case numberParsingError(parsing: String, source: String)
        /// Current operation is not supported for the described type of data item.
        case operationNotSupportedFor(_ typeDescription: String)

        public var message: String {
            switch self {
            case .missingDataItem:
                return "Data item is not defined"
            case .missingFilter:
                return "Filter is not defined"
            case let .numberParsingError(parsing, source):
                return "\(source) value \(parsing) cannot be parsed as a number"
            case let .operationNotSupportedFor(type):
                return "Data item (\(type)) is not supported for this operation"
            }
        }
    }
    public let type: ErrorType
    public let condition: Condition

    public var description: String {
        "Matching operation failed: \(type.localizedDescription). \(type.message). Condition: \(condition)"
    }
}
