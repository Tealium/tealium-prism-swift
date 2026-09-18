//
//  Tealium+ContextAPITests.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 5/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumContextAPITests: TealiumBaseTests {
    func test_contextAPI_wrapper_works_on_our_queue() throws {
        let contextAPICompleted = expectation(description: "Context API fetch completed")

        guard let jsonData = try? Tealium.jsonEncoder.encode(EngineResponse()) else {
            XCTFail("Failed to create test data")
            return
        }
        client.result = .success(NetworkResponse(
            data: jsonData,
            urlResponse: .successful()
        ))

        config.addModule(Modules.contextAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setRegion(.usEast).setReferrer("https://example.com")
        }))

        let teal = createTealium()

        teal.contextAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result)
            contextAPICompleted.fulfill()
        }

        waitOnQueue(queue: queue)
    }

    func test_contextAPI_wrapper_throws_errors_if_not_enabled() throws {
        let contextAPICompleted = expectation(description: "Context API fetch completed")
        config.addModule(Modules.contextAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()

        teal.contextAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(module == "\(ContextAPIModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            contextAPICompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_contextAPI_wrapper_throws_errors_if_not_added() throws {
        let contextAPICompleted = expectation(description: "Context API fetch completed")
        let teal = createTealium()

        teal.contextAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(module == "\(ContextAPIModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            contextAPICompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_contextAPI_handles_network_error() throws {
        let contextAPICompleted = expectation(description: "Context API fetch completed")

        client.setError(.urlError(URLError(.notConnectedToInternet)))

        config.addModule(Modules.contextAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setRegion(.usEast)
        }))

        let teal = createTealium()

        teal.contextAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))

            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError(let contextAPIError) = error,
                      case .networkError = contextAPIError else {
                    XCTFail("Expected underlyingError with networkError, got \(error)")
                    return
                }
                contextAPICompleted.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }

    func test_contextAPI_handles_http_error() throws {
        let contextAPICompleted = expectation(description: "Context API fetch completed")

        guard let url = URL(string: "https://example.com"),
              let errorResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil) else {
            XCTFail("Failed to create test URL or response")
            return
        }
        client.result = .success(NetworkResponse(data: Data(), urlResponse: errorResponse))

        config.addModule(Modules.contextAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setRegion(.usEast)
        }))

        let teal = createTealium()

        teal.contextAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))

            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError = error else {
                    XCTFail("Expected underlyingError, got \(error)")
                    return
                }
                contextAPICompleted.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }
}
