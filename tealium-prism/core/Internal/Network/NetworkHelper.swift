//
//  NetworkHelper.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A convenience helper for standard, **uncompressed** network requests.
///
/// This is a thin short-circuit over `NetworkClient`: bodies are never compressed and no logging
/// happens here — request/response logging and tracing are consolidated in `NetworkClient`.
/// For anything non-standard (gzip, custom headers/requests), build a `RequestBuilder` (or a
/// `URLRequest`) and send it through `NetworkClient` directly.
class NetworkHelper: NetworkHelperProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = HTTPClient.shared) {
        self.networkClient = networkClient
    }

    func get(url: URLConvertible,
             etag: String? = nil,
             additionalHeaders: [String: String]? = nil,
             completion: @escaping (NetworkResult) -> Void) -> any Disposable {
        networkClient.sendRequest(.makeGET(url: url, etag: etag)
            .additionalHeaders(additionalHeaders),
                                  completion: completion)
    }

    func post(url: URLConvertible,
              body: DataObject,
              additionalHeaders: [String: String]? = nil,
              completion: @escaping (NetworkResult) -> Void) -> any Disposable {
        networkClient.sendRequest(.makePOST(url: url, json: body)
            .additionalHeaders(additionalHeaders),
                                  completion: completion)
    }
}
