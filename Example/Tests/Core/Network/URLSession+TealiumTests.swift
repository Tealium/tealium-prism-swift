//
//  URLSession+TealiumTests.swift
//  tealium-prism_Tests
//
//  Created by Denis Guzov on 21/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class URLSessionTealiumTests: XCTestCase {

    // MARK: - makeResponse mapping
    private let response500 = HTTPURLResponse(url: URLRequest.defaultURL, statusCode: 500, httpVersion: nil, headerFields: nil)

    func test_makeResponse_succeeds_with_data_and_2xx_response() throws {
        let response = try URLSession.makeResponse(data: Data("body".utf8), response: HTTPURLResponse.successful(), error: nil)
        XCTAssertEqual(response.data, Data("body".utf8))
        XCTAssertEqual(response.urlResponse.statusCode, 200)
    }

    func test_makeResponse_preserves_body_data_on_non200_status() throws {
        let urlResponse = try XCTUnwrap(response500)
        let bodyData = Data("body".utf8)
        XCTAssertThrows(try URLSession.makeResponse(data: bodyData, response: urlResponse, error: nil)) { (error: NetworkError) in
            guard case let .non200Status(_, data) = error.type else {
                XCTFail("Expected non200Status, got \(error.type)")
                return
            }
            XCTAssertEqual(data, bodyData)
        }
    }

    func test_makeResponse_preserves_url_response_on_non200_status() throws {
        let urlResponse = try XCTUnwrap(response500)
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: urlResponse, error: nil)) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .non200Status)
            XCTAssertNotNil(error.urlResponse)
        }
    }

    func test_makeResponse_prefers_non200_status_over_transport_error() throws {
        let urlResponse = try XCTUnwrap(response500)
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: urlResponse, error: URLError(.cancelled))) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .non200Status)
            XCTAssertNotNil(error.urlResponse)
        }
    }

    func test_makeResponse_preserves_url_response_on_transport_error() {
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: HTTPURLResponse.successful(), error: URLError(.cancelled))) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .cancelled)
            XCTAssertNotNil(error.urlResponse)
        }
    }

    func test_makeResponse_maps_cancelled_urlError_to_cancelled() {
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: nil, error: URLError(.cancelled))) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .cancelled)
            XCTAssertNil(error.urlResponse)
        }
    }

    func test_makeResponse_maps_non_cancelled_urlError_to_urlError() {
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: nil, error: URLError(.notConnectedToInternet))) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .urlError)
            XCTAssertNil(error.urlResponse)
        }
    }

    func test_makeResponse_maps_non_urlError_to_unknown() {
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: nil, error: TestError.unknown)) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .unknown)
            XCTAssertNil(error.urlResponse)
        }
    }

    func test_makeResponse_with_nil_response_and_nil_error_fails_with_unknown() {
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: nil, error: nil)) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .unknown)
            XCTAssertNil(error.urlResponse)
        }
    }

    func test_makeResponse_with_2xx_response_and_nil_data_fails_with_unknown() {
        XCTAssertThrows(try URLSession.makeResponse(data: nil, response: HTTPURLResponse.successful(), error: nil)) { (error: NetworkError) in
            XCTAssertNetworkError(error, is: .unknown)
            XCTAssertNotNil(error.urlResponse)
        }
    }

    // MARK: - send integration

    // URLProtocolMock seems not to be working on watchos
#if !os(watchOS)
    private let queue = TealiumQueue(label: "testQueue", qos: .userInteractive)
    lazy var config: NetworkConfiguration = {
        var config = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                          interceptors: [],
                                          interceptorManagerFactory: MockInterceptorManager.self,
                                          queue: queue)
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return config
    }()
    lazy var client = HTTPClient(configuration: config, logger: nil)

    override func tearDown() {
        URLProtocolMock.reset()
    }

    func test_send_succeeds_with_empty_body() {
        let expect = expectation(description: "Request will complete with success and empty Data")
        URLProtocolMock.succeedingWith(data: Data(), response: .successful())
        _ = client.session.send(URLRequest()) { result in
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, Data())
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }

    func test_send_surfaces_empty_data_when_protocol_body_is_nil() {
        let expect = expectation(description: "URLSession delivers empty Data even when the protocol provides a nil body")
        URLProtocolMock.replyingWith(.always((nil, .successful(), nil)))
        _ = client.session.send(URLRequest()) { result in
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, Data())
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }

    // Hits a real server that replies 204 No Content to prove URLSession delivers non-nil (empty) Data
    // for an empty-body 2xx response, so the `guard let data` branch in `makeResponse` is never taken.
    // Requires network access; uses a real URLSession (no URLProtocolMock).
    func test_real_204_request_succeeds_with_non_nil_empty_body() throws {
        try skip("Skip this test as it will actually perform an HTTP request that we don't want to perform in CI")
        let expect = expectation(description: "Real 204 response completes with success and non-nil empty Data")
        let request = try URLRequest(url: "https://www.google.com/generate_204".asUrl())
        config = .default
        _ = client.session.send(request) { result in
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, Data())
                XCTAssertEqual(value.urlResponse.statusCode, 204)
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }
#endif
}
