//
//  NetworkResponse.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/06/23.
//

import Foundation

/// A successful response returned by the NetworkClient
public struct NetworkResponse {
    public let data: Data
    public let urlResponse: HTTPURLResponse
}

/// A successful Result with a NetwprkResponse or a failed Result with NetworkError, returned by the NetworkClient
public typealias NetworkResult = Result<NetworkResponse, NetworkError>
