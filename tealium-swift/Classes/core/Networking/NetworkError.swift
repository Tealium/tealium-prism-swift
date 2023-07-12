//
//  NetworkError.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

extension URLError {
    static let connectionErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .networkConnectionLost,
        .notConnectedToInternet,
        .secureConnectionFailed,
        .internationalRoamingOff,
        .callIsActive,
        .dataNotAllowed
    ]
    
    var isConnectionError: Bool {
        URLError.connectionErrorCodes.contains(self.code)
    }
}

public enum NetworkError: Error, Equatable {
    case non200Status(Int)
    case cancelled
    case urlError(URLError)
    case unknown(Error?)
    
    var isRetryable: Bool {
        switch self {
        case .non200Status(let status):
            return NetworkError.defaultRetriableHTTPStatusCodes.contains(status)
        case .urlError(let urlError):
            return NetworkError.defaultRetriableURLErrorCodes.contains(urlError.code)
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
    
    var isConnectionError: Bool {
        guard case let .urlError(urlError) = self else {
            return false
        }
        return urlError.isConnectionError
    }
    
    static let defaultRetriableURLErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .networkConnectionLost,
        .dnsLookupFailed,
        .notConnectedToInternet,
        .badServerResponse,
        .secureConnectionFailed,
        .serverCertificateHasBadDate,
        .serverCertificateNotYetValid,
        .cannotLoadFromNetwork,
        .downloadDecodingFailedMidStream,
        .downloadDecodingFailedToComplete,
        .internationalRoamingOff,
        .callIsActive,
        .dataNotAllowed,
        .backgroundSessionInUseByAnotherProcess,
        .backgroundSessionWasDisconnected
    ]
    static let defaultRetriableHTTPStatusCodes: Set<Int> = [
        408,
        429,
        500,
        502,
        503,
        504
    ]
}
