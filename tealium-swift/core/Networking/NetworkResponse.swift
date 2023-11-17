//
//  NetworkResponse.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A successful response returned by the NetworkClient
public struct NetworkResponse {
    public let data: Data
    public let urlResponse: HTTPURLResponse
}

/// A successful Result with a NetworkResponse or a failed Result with NetworkError, returned by the NetworkClient
public typealias NetworkResult = Result<NetworkResponse, NetworkError>

extension NetworkResult {
    func shortDescription() -> String {
        switch self {
        case .failure(let error):
            return "failed with \(error.localizedDescription)"
        case .success(let response):
            return "succeded with \(response.urlResponse.statusCode) status code"
        }
    }
}
