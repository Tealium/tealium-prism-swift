//
//  NetworkErrorType.swift
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
public enum NetworkErrorType: Error, ErrorEnum {
    /// A request completed with a non 2xx status code and the optional data from the Body.
    case non200Status(Int, Data?)
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
        case .non200Status(let status, _):
            return NetworkErrorType.retriableHTTPStatusCodes.contains(status)
        case .urlError(let urlError):
            return NetworkErrorType.retriableURLErrorCodes.contains(urlError.code)
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
