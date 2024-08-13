//
//  NetworkHelper.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class NetworkHelper: NetworkHelperProtocol {
    private static let decoder = Tealium.jsonDecoder
    public let networkClient: NetworkClient
    let onLogger: Observable<TealiumLoggerProvider>
    init(networkClient: NetworkClient = HTTPClient.shared, onLogger: Observable<TealiumLoggerProvider> = .Just(TealiumLogger(logger: TealiumOSLogger(), minLogLevel: .constant(.trace)))) {
        self.networkClient = networkClient
        self.onLogger = onLogger
    }

    private func send(requestBuilder: @autoclosure () throws -> RequestBuilder, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        let completion: (NetworkResult) -> Void = { [weak self] result in
            self?.onLogger.map { logger in
                switch result {
                case .success:
                    logger.trace
                case .failure:
                    logger.error
                }
            }
            .subscribeOnce { limitedLogger in
                limitedLogger?.log(category: LogCategory.networkHelper,
                                   message: "Completed request with result \(result.shortDescription())")
            }
            completion(result)
        }
        do {
            let request = try requestBuilder().build()
            onLogger.subscribeOnce { logger in
                logger.trace?.log(category: LogCategory.networkHelper,
                                  message: "Built request \(request)")
            }
            return networkClient.sendRequest(request, completion: completion)
        } catch {
            onLogger.subscribeOnce { logger in
                logger.error?.log(category: LogCategory.networkHelper,
                                  message: "Failed to build request")
            }
            completion(.failure(.unknown(error)))
            return Subscription { }
        }
    }

    public func get(url: URLConvertible, etag: String? = nil, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        send(requestBuilder: try .makeGET(url: url, etag: etag),
             completion: completion)
    }

    public func getJsonAsDictionary(url: URLConvertible, etag: String? = nil, completion: @escaping (JSONResult) -> Void) -> Disposable {
        get(url: url, etag: etag) { result in
            completion(result.flatMap { response in
                do {
                    let json = try JSONSerialization.jsonObject(with: response.data)
                    if let dictionary = json as? [String: Any] {
                        return .success(JSONResponse(json: dictionary, urlResponse: response.urlResponse))
                    } else {
                        return .failure(.unknown(ParsingError.jsonIsNotADictionary(json)))
                    }
                } catch {
                    return .failure(.unknown(error))
                }
            })
        }
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

    public func post(url: URLConvertible, body: [String: Any], completion: @escaping (NetworkResult) -> Void) -> Disposable {
        send(requestBuilder: try .makePOST(url: url, gzippedJson: body),
             completion: completion)
    }
}
