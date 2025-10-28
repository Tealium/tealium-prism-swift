//
//  NetworkHelper.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A helper class that provides convenient methods for common network operations.
public class NetworkHelper: NetworkHelperProtocol {
    private static let decoder = Tealium.jsonDecoder
    /// The underlying network client used for sending requests.
    public let networkClient: NetworkClient
    let logger: LoggerProtocol?

    init(networkClient: NetworkClient = HTTPClient.shared, logger: TealiumLogger?) {
        self.networkClient = networkClient
        self.logger = logger
    }

    private func send(requestBuilder: RequestBuilder, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        let completion: (NetworkResult) -> Void = { [weak self] result in
            self?.logger?.log(level: result.logLevel(),
                              category: LogCategory.networkHelper,
                              "Completed request: \(result.shortDescription())")
            completion(result)
        }
        do {
            logger?.trace(category: LogCategory.networkHelper,
                          "Building request\n\(requestBuilder)")
            let request = try requestBuilder.build()
                logger?.trace(category: LogCategory.networkHelper,
                              "Built request \(request)")
            return networkClient.sendRequest(request, completion: completion)
        } catch {
            logger?.error(category: LogCategory.networkHelper,
                          "Failed to build request")
            completion(.failure(.unknown(error)))
            return Disposables.disposed()
        }
    }

    public func get(url: URLConvertible, etag: String? = nil, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        send(requestBuilder: .makeGET(url: url, etag: etag),
             completion: completion)
    }

    public func getJsonAsObject<T: Codable>(url: URLConvertible, etag: String? = nil, completion: @escaping (ObjectResult<T>) -> Void) -> Disposable {
        get(url: url, etag: etag) { result in
            completion(result.flatMap { response in
                do {
                    return .success(ObjectResponse(object: try Self.decoder.decode(T.self, from: response.data),
                                                   urlResponse: response.urlResponse))
                } catch {
                    return .failure(.unknown(error))
                }
            })
        }
    }

    public func post(url: URLConvertible, body: DataObject, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        send(requestBuilder: .makePOST(url: url, gzippedJson: body),
             completion: completion)
    }
}
