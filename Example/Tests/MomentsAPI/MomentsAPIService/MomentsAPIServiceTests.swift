//
//  MomentsAPIServiceTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MomentsAPIServiceTests: MomentsAPIServiceBaseTests {

    func test_fetchEngineResponse_returns_error_when_engineID_is_empty() {
        service.fetchEngineResponse(engineID: "", visitorID: "visitor123") { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .invalidEngineID = error else {
                    XCTFail("Expected invalidEngineID, got \(error)")
                    return
                }
            }
        }
    }

    func test_fetchEngineResponse_sets_correct_headers() throws {
        let expectation = expectation(description: "Network request made")
        let customReferrer = "https://custom-referrer.com"
        try mockNetworkHelper.encodeResult(EngineResponse())
        mockNetworkHelper.requests.subscribe { request in
            guard case .get(_, _, let headers) = request,
                  let headers = headers else {
                return
            }
            XCTAssertEqual(headers["Accept"], "application/json")
            XCTAssertEqual(headers["Referer"], customReferrer)
            expectation.fulfill()
        }.addTo(DisposableContainer())

        service = createService(referrer: customReferrer)
        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { _ in }

        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_uses_default_referrer_when_nil() throws {
        let expectation = expectation(description: "Network request made")
        let expectedReferrer = "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html"
        try mockNetworkHelper.encodeResult(EngineResponse())
        mockNetworkHelper.requests.subscribe { request in
            guard case .get(_, _, let headers) = request,
                  let headers = headers else {
                return
            }
            XCTAssertEqual(headers["Referer"], expectedReferrer)
            expectation.fulfill()
        }.addTo(DisposableContainer())

        service = createService(referrer: nil)
        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { _ in }

        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_handles_successful_response() throws {
        let expectation = expectation(description: "Fetch succeeds")

        let mockResponse = EngineResponse(
            audiences: ["audience1", "audience2"],
            badges: ["badge1"],
            flags: ["isVip": true],
            dates: ["lastPurchase": 1_731_061_966_000],
            metrics: ["lifetimeValue": 1000.50],
            properties: ["segment": "premium"]
        )
        try mockNetworkHelper.encodeResult(mockResponse)

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertEqual(response.audiences, ["audience1", "audience2"])
                XCTAssertEqual(response.badges, ["badge1"])
                XCTAssertEqual(response.flags?["isVip"], true)
                XCTAssertEqual(response.dates?["lastPurchase"], 1_731_061_966_000)
                XCTAssertEqual(response.metrics?["lifetimeValue"], 1000.50)
                XCTAssertEqual(response.properties?["segment"], "premium")
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_handles_json_parsing_error() {
        let expectation = expectation(description: "Fetch fails with JSON parsing error")

        let networkResponse = NetworkResponse(
            data: Data("invalid json".utf8),
            urlResponse: .successful()
        )
        mockNetworkHelper.result = .success(networkResponse)

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .networkError(let networkError) = error,
                      case .unknown(let decodingError) = networkError else {
                    XCTFail("Expected networkError, got \(result)")
                    return
                }
                XCTAssertTrue(decodingError is DecodingError)
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_handles_network_error() {
        let expectation = expectation(description: "Fetch fails with network error")

        let networkError: NetworkError = .urlError(URLError(.notConnectedToInternet))
        mockNetworkHelper.result = .failure(networkError)

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .networkError = error else {
                    XCTFail("Expected networkError, got \(error)")
                    return
                }
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_handles_empty_response() throws {
        let expectation = expectation(description: "Fetch handles empty response")
        try mockNetworkHelper.encodeResult(EngineResponse())

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertNil(response.audiences)
                XCTAssertNil(response.badges)
                XCTAssertNil(response.flags)
                XCTAssertNil(response.dates)
                XCTAssertNil(response.metrics)
                XCTAssertNil(response.properties)
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_handles_partial_response() throws {
        let expectation = expectation(description: "Fetch handles partial response")

        let mockResponse = EngineResponse(
            audiences: ["audience1"],
            badges: nil,
            flags: nil,
            dates: nil,
            metrics: nil,
            properties: nil
        )
        try mockNetworkHelper.encodeResult(mockResponse)

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertEqual(response.audiences, ["audience1"])
                XCTAssertNil(response.badges)
                XCTAssertNil(response.flags)
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }

    // MARK: - URL Building Tests

    func test_fetchEngineResponse_builds_correct_url_for_region() throws {
        let disposableContainer = DisposableContainer()
        let region = MomentsAPIRegion.germany
        let testService = createService(region: region)
        let expectation = expectation(description: "Network request made for \(region.rawValue)")

        try mockNetworkHelper.encodeResult(EngineResponse())
        mockNetworkHelper.requests.subscribeOnce { request in
            guard case .get(let url, _, _) = request else {
                return
            }
            guard let capturedURL = try? url.asUrl() else {
                return
            }
            let urlString = capturedURL.absoluteString
            // Only process if this URL is for the expected region
            guard urlString.contains(region.rawValue) else {
                XCTFail("URL should contain \(region.rawValue), got: \(urlString)")
                return
            }
            disposableContainer.dispose()
            expectation.fulfill()
        }.addTo(disposableContainer)
        testService.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { _ in }
        waitForDefaultTimeout()
    }

    // MARK: - HTTP Error Status Code Tests

    func test_fetchEngineResponse_handles_http_error_status_codes() {
        let expectation = expectation(description: "Fetch fails with \(400) error")
        mockNetworkHelper.result = .failure(.non200Status(400))

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsFailure(result) { error in
                // Empty data with non-2xx status results in DecodingError wrapped as networkError
                guard case let .networkError(networkError) = error,
                      case let .non200Status(status) = networkError else {
                    XCTFail("Expected networkError for \(400) status, got \(error)")
                    return
                }
                XCTAssertEqual(status, 400)
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }

    // MARK: - Response Parsing Tests

    func test_fetchEngineResponse_handles_response_with_extra_fields() {
        let expectation = expectation(description: "Fetch handles response with extra fields")

        let jsonString = """
        {
            "audiences": ["audience1"],
            "badges": ["badge1"],
            "flags": {"isVip": true},
            "extraField": "should be ignored",
            "unknownArray": [1, 2, 3],
            "dates": {"lastPurchase": 1731061966000},
            "metrics": {"lifetimeValue": 1000.50},
            "properties": {"segment": "premium"}
        }
        """

        let networkResponse = NetworkResponse(
            data: Data(jsonString.utf8),
            urlResponse: .successful()
        )
        mockNetworkHelper.result = .success(networkResponse)

        service.fetchEngineResponse(engineID: "engine", visitorID: "visitor") { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertEqual(response.audiences, ["audience1"])
                XCTAssertEqual(response.badges, ["badge1"])
                XCTAssertEqual(response.flags?["isVip"], true)
                XCTAssertEqual(response.dates?["lastPurchase"], 1_731_061_966_000)
                XCTAssertEqual(response.metrics?["lifetimeValue"], 1000.50)
                XCTAssertEqual(response.properties?["segment"], "premium")
                expectation.fulfill()
            }
        }

        waitForDefaultTimeout()
    }
}
