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
}

/// A successful Result with a NetworkResponse or a failed Result with NetworkError, returned by the NetworkClient
public typealias NetworkResult = Result<NetworkResponse, NetworkError>

extension NetworkResult {
    func shortDescription() -> String {
        switch self {
        case .failure(let error):
            if case let .non200Status(status) = error, status == 304 {
                return "resource not modified"
            } else {
                return "failed with \(error)"
            }
        case .success(let response):
            return "succeeded with \(response.urlResponse.statusCode) status code"
        }
    }

    func logLevel() -> LogLevel {
        switch self {
        case .success:
            .trace
        case .failure(let error):
            if case let .non200Status(statusCode) = error, statusCode == 304 {
                .trace
            } else {
                .error
            }
        }
    }
}
