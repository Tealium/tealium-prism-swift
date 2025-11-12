//
//  NetworkError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

extension URLError {
    static let clientConnectionErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .networkConnectionLost,
        .notConnectedToInternet,
        .secureConnectionFailed,
        .internationalRoamingOff,
        .callIsActive,
        .dataNotAllowed
    ]

    var isClientConnectionError: Bool {
        URLError.clientConnectionErrorCodes.contains(self.code)
    }
}

/**
 * An error reported by the NetworkClient.
 */
public enum NetworkError: Error, ErrorEnum {
    /// A request completed with a non 2xx status code
    case non200Status(Int)
    /// A request was cancelled before completion
    case cancelled
    /// A `URLError` was returned by the `URLSession.dataTask` completion
    case urlError(URLError)
    /**
     * An unknown error occurred.
     *
     * Check the inner error to have details about what might have happened.
     */
    case unknown(Error?)

    /// Returns `true` if the error is assumed to be retriable.
    var isRetryable: Bool {
        switch self {
        case .non200Status(let status):
            return NetworkError.retriableHTTPStatusCodes.contains(status)
        case .urlError(let urlError):
            return NetworkError.retriableURLErrorCodes.contains(urlError.code)
        default:
            return false
        }
    }

    /// Returns `true` if the error happened due to potential connection missing from the client.
    var isClientConnectionError: Bool {
        guard case let .urlError(urlError) = self else {
            return false
        }
        return urlError.isClientConnectionError
    }

    static let retriableURLErrorCodes: Set<URLError.Code> = [
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

    static let retriableHTTPStatusCodes: Set<Int> = [
        408,
        429,
        500,
        502,
        503,
        504
    ]
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled):
            return true
        case let (.non200Status(lhsStatus), .non200Status(rhsStatus)):
            return lhsStatus == rhsStatus
        case let (.urlError(lhsError), .urlError(rhsError)):
            return lhsError.code == rhsError.code
        case let (.unknown(lhsError), .unknown(rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}
