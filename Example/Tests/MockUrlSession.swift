//
//  MockUrlSession.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/05/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import tealium_swift
extension URLRequest {
    static let defaultURL = URL(string: "https://www.tealium.com")!
    init(_ url: URL = defaultURL, method: String = "GET") {
        self.init(url: url)
        self.httpMethod = method
    }
}

extension HTTPURLResponse {
    static func successful(url: URL = URLRequest.defaultURL) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
}

extension NetworkResponse {
    static func successful() -> NetworkResponse {
        NetworkResponse(data: Data(), urlResponse: .successful())
    }
}

enum MockReply {
    typealias Response = (Data?, HTTPURLResponse?, Error?)
    case always(Response)
    case list([Response])
    case loop([Response])
    case keyed([String: Response])
    
    mutating func popNext(_ request: URLRequest? = nil) -> Response {
        switch self {
        case .always(let response):
            return response
        case .list(var responses):
            if responses.count > 0 {
                let response = responses.removeFirst()
                self = .list(responses)
                return response
            }
        case .loop(var responses):
            if responses.count > 0 {
                let response = responses.removeFirst()
                responses.append(response)
                self = .list(responses)
                return response
            }
        case .keyed(let dict):
            if let requestUrl = request?.url?.absoluteString, let response = dict[requestUrl] {
                return response
            }
        }
        fatalError("Reply \(self) has no responses")
    }
    
    func peak(_ request: URLRequest? = nil) -> Response {
        switch self {
        case .always(let response):
            return response
        case .list(let responses):
            if responses.count > 0, let response = responses.first {
                return response
            }
        case .loop(let responses):
            if responses.count > 0, let response = responses.first {
                return response
            }
        case .keyed(let dict):
            if let requestUrl = request?.url?.absoluteString, let response = dict[requestUrl] {
                return response
            }
        }
        fatalError("Reply \(self) has no responses for request \(String(describing: request))")
    }
}

class URLProtocolMock: URLProtocol {
    
    typealias Waiting = (@escaping () -> ()) -> ()
    static var waiting: Waiting = { callback in callback() }
    static var reply: MockReply = .always((nil, nil, nil))
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all types of requests
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Required to be implemented here. Just return what is passed
        return request
    }
    
    static func succeedingWith(data: Data, response: HTTPURLResponse) {
        reply = .always((data, response, nil))
    }
    
    static func failingWith(error: Error) {
        reply = .always((nil, nil, error))
    }
    
    static func replyingWith(_ newReply: MockReply) {
        reply = newReply
    }
    
    static func delaying(_ waitingBlock: @escaping Waiting) {
        waiting = waitingBlock
    }
    
    override func startLoading() {
        URLProtocolMock.waiting {
            let completionData = URLProtocolMock.reply.popNext(self.request)
            if let response = completionData.1 {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = completionData.0 {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let error = completionData.2 {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            // Send the signal that we are done returning our mock response
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        // Required to be implemented. Do nothing here.
    }
}
