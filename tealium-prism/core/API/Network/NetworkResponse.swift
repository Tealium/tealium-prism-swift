//
//  NetworkResponse.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 21/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A successful response returned by the NetworkClient
public struct NetworkResponse {
    /// The response data.
    public let data: Data
    /// The HTTP URL response.
    public let urlResponse: HTTPURLResponse

    func shortDescription() -> String {
        "\(urlResponse.statusCode) status code"
    }

    func longDescription() -> String {
        "\(response: urlResponse)\n\(body: data)"
    }
}

/// An error returned from an http request.
public struct NetworkError: Error {
    /// The type of error.
    public let type: NetworkErrorType

    /// The response from the server, if it was successfully returned.
    public let urlResponse: HTTPURLResponse?

    var isRetryable: Bool {
        type.isRetryable
    }

    var isClientConnectionError: Bool {
        type.isClientConnectionError
    }

    func shortDescription() -> String {
        switch type {
        case .cancelled:
            "Request was cancelled"
        case .urlError:
            "URLError occurred"
        case let .non200Status(status, _):
            if status == 304 {
                "Resource not modified"
            } else {
                "Non 200 status \(status)"
            }
        case .unknown:
            "Unknown error occurred"
        }
    }

    func longDescription() -> String {
        let baseDescription = switch type {
        case .cancelled:
            "Request was cancelled"
        case let .urlError(error):
            "URLError occurred\n\(error)"
        case let .non200Status(status, data):
            "Non 200 status \(status)".with(data) { "\n\(body: $0)" }
        case let .unknown(error):
            "Unknown error occurred".with(error) { "\n\($0)" }
        }
        return baseDescription.with(urlResponse) { "\n\(response: $0)" }
    }
}

/// A successful Result with a NetworkResponse or a failed Result with NetworkError, returned by the NetworkClient
public typealias NetworkResult = Result<NetworkResponse, NetworkError>

extension NetworkResult {

    var urlResponse: HTTPURLResponse? {
        switch self {
        case .success(let response): response.urlResponse
        case .failure(let error): error.urlResponse
        }
    }

    func shortDescription() -> String {
        switch self {
        case .success(let response):
            "Succeeded with: \(response.shortDescription())"
        case .failure(let error):
            "Failed with: \(error.shortDescription())"
        }
    }

    func longDescription() -> String {
        switch self {
        case let .success(response): "Successful Response:\n\(response.longDescription())"
        case let .failure(error): "Failure Response:\n\(error.longDescription())"
        }
    }

    func logLevel() -> LogLevel {
        switch self {
        case .success:
            .debug
        case .failure(let error):
            if case let .non200Status(statusCode, _) = error.type, statusCode == 304 {
                .debug
            } else {
                .error
            }
        }
    }
}
