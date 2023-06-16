//
//  NetworkError.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

public enum NetworkError: Error, Equatable {
    case non200Status(Int)
    case cancelled
    case urlError(URLError)
    case unknown(Error?)
    
    var isRetryable: Bool {
        switch self {
        case .non200Status(let status):
            return status == 429 || (500..<600).contains(status)
        case .urlError:
            return true // Most of URLErrors are retryable
        default:
            return false
        }
    }

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled):
            return true
        case (.non200Status(let lhsStatus), .non200Status(let rhsStatus)):
            return lhsStatus == rhsStatus
        case (.urlError(let lhsError), .urlError(let rhsError)):
            return lhsError.code == rhsError.code
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}
