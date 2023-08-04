//
//  NetworkHelper.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class NetworkHelper: NetworkHelperProtocol {
    private static let decoder = JSONDecoder()
    public let networkClient: NetworkClientProtocol
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    public static let shared = NetworkHelper()

    private func send(requestBuilder: @autoclosure () throws -> RequestBuilder, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        do {
            let request = try requestBuilder().build()
            return networkClient.sendRequest(request, completion: completion)
        } catch {
            completion(.failure(.unknown(error)))
            return TealiumSubscription { }
        }
    }

    public func get(url: URLConvertible, etag: String? = nil, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        send(requestBuilder: .makeGET(url: url, etag: etag),
             completion: completion)
    }

    public func getJsonAsDictionary(url: URLConvertible, etag: String? = nil, completion: @escaping (JSONResult) -> Void) -> TealiumDisposable {
        send(requestBuilder: .makeGET(url: url, etag: etag)) { result in
            completion(result.flatMap { response in
                do {
                    let json = try JSONSerialization.jsonObject(with: response.data)
                    if let dictionary = json as? [String: Any] {
                        return .success(dictionary)
                    } else {
                        return .failure(.unknown(ParsingError.jsonIsNotADictionary(json)))
                    }
                } catch {
                    return .failure(.unknown(error))
                }
            })
        }
    }

    public func getJsonAsObject<T: Codable>(url: URLConvertible, etag: String? = nil, completion: @escaping (CodableResult<T>) -> Void) -> TealiumDisposable {
        send(requestBuilder: .makeGET(url: url, etag: etag)) { result in
            completion(result.flatMap { response in
                do {
                    return .success(try Self.decoder.decode(T.self, from: response.data))
                } catch {
                    return .failure(.unknown(error))
                }
            })
        }
    }

    public func post(url: URLConvertible, body: [String: Any], completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        send(requestBuilder: try .makePOST(url: url, gzippedJson: body),
             completion: completion)
    }
}
