//
//  NetworkHelperTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

struct MockResultObject: Codable, Equatable {
    let keyString: String
    let keyInt: Int
}

struct NonCodableObject {}

final class NetworkHelperTests: XCTestCase {
    let url = "https://www.tealium.com"
    let mockClient = MockNetworkClient(result: .success(.init(data: Data(), urlResponse: .successful())))
    lazy var networkHelper = NetworkHelper(networkClient: mockClient, logger: nil)
    func test_get_returns_mocked_result() {
        let networkCallCompleted = expectation(description: "Network Call completed")
        _ = networkHelper.get(url: url) { result in
            XCTAssertResultIsSuccess(result)
            networkCallCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_get_with_etag_adds_if_none_match_header() {
        let requestSended = expectation(description: "URLRequest was sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(request.url?.absoluteString, self.url)
            XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "some etag")
            requestSended.fulfill()
        }
        _ = networkHelper.get(url: url, etag: "some etag") { _ in }
        waitForDefaultTimeout()
    }

    func test_getJsonAsObject_returns_codable_result() {
        let networkCallCompleted = expectation(description: "Network Call completed")
        let object = MockResultObject(keyString: "value", keyInt: 1)
        guard let data = try? JSONEncoder().encode(object) else {
            XCTFail("MockResultObject could not be encoded")
            return
        }
        mockClient.result = .success(NetworkResponse(data: data, urlResponse: .successful()))
        _ = networkHelper.getJsonAsObject(url: url) { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertEqual(response.object, object)
            }
            networkCallCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_getJsonAsObject_with_etag_adds_if_none_match_header() {
        let requestSended = expectation(description: "URLRequest was sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(request.url?.absoluteString, self.url)
            XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "some etag")
            requestSended.fulfill()
        }
        _ = networkHelper.getJsonAsObject(url: url, etag: "some etag") { (_: ObjectResult<MockResultObject>) in }
        waitForDefaultTimeout()
    }

    func test_getJsonAsObject_fails_when_data_is_malformed() {
        let networkCallCompleted = expectation(description: "Network Call completed")
        mockClient.result = .success(NetworkResponse(data: Data(), urlResponse: .successful()))
        _ = networkHelper.getJsonAsObject(url: url) { (result: ObjectResult<MockResultObject>)  in
            XCTAssertResultIsFailure(result)
            networkCallCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_getJsonAsDictionary_returns_dictionary_result() {
        let networkCallCompleted = expectation(description: "Network Call completed")
        let object = MockResultObject(keyString: "value", keyInt: 1)
        guard let data = try? JSONEncoder().encode(object) else {
            XCTFail("MockResultObject could not be encoded")
            return
        }
        mockClient.result = .success(NetworkResponse(data: data, urlResponse: .successful()))
        _ = networkHelper.getJsonAsDataObject(url: url) { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertEqual(response.object.get(key: "keyString"), "value")
                XCTAssertEqual(response.object.get(key: "keyInt"), 1)
            }
            networkCallCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_getJsonAsDictionary_with_etag_adds_if_none_match_header() {
        let requestSent = expectation(description: "URLRequest was sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(request.url?.absoluteString, self.url)
            XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "some etag")
            requestSent.fulfill()
        }
        _ = networkHelper.getJsonAsDataObject(url: url, etag: "some etag") { _ in }
        waitForDefaultTimeout()
    }

    func test_getJsonAsDictionary_fails_when_response_is_an_array() {
        let networkCallCompleted = expectation(description: "Network Call completed")
        let object = MockResultObject(keyString: "value", keyInt: 1)
        guard let data = try? JSONEncoder().encode([object]) else {
            XCTFail("MockResultObject could not be encoded")
            return
        }
        mockClient.result = .success(NetworkResponse(data: data, urlResponse: .successful()))
        _ = networkHelper.getJsonAsDataObject(url: url) { result in
            XCTAssertResultIsFailure(result)
            networkCallCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_post_returns_mocked_result() {
        let networkCallCompleted = expectation(description: "Network Call completed")
        _ = networkHelper.post(url: url, body: DataObject()) { result in
            XCTAssertResultIsSuccess(result)
            networkCallCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_post_sends_correct_urlRequest() {
        let requestSended = expectation(description: "URLRequest was sent")
        let dataObject: DataObject = ["key": "value"]
        mockClient.requestDidSend = { request in
            XCTAssertEqual(request.url?.absoluteString, self.url)
            XCTAssertEqual(request.httpBody?.isGzipped, true, "Data is not gzipped")
            XCTAssertEqual(request.httpBody, try? Tealium.jsonEncoder.encode(AnyCodable(dataObject.asDictionary())).gzipped(level: .bestCompression))
            requestSended.fulfill()
        }
        _ = networkHelper.post(url: url, body: dataObject) { _ in }
        waitForDefaultTimeout()
    }
}
