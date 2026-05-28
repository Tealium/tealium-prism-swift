//
//  Tealium+MomentsAPITests.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 5/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumMomentsAPITests: TealiumBaseTests {
    func test_momentsAPI_wrapper_works_on_our_queue() throws {
        let momentsAPICompleted = expectation(description: "Moments API fetch completed")

        guard let jsonData = try? Tealium.jsonEncoder.encode(EngineResponse()) else {
            XCTFail("Failed to create test data")
            return
        }
        client.result = .success(NetworkResponse(
            data: jsonData,
            urlResponse: .successful()
        ))

        config.addModule(Modules.momentsAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setRegion(.usEast).setReferrer("https://example.com")
        }))

        let teal = createTealium()

        teal.momentsAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result)
            momentsAPICompleted.fulfill()
        }

        waitOnQueue(queue: queue)
    }

    func test_momentsAPI_wrapper_throws_errors_if_not_enabled() throws {
        let momentsAPICompleted = expectation(description: "Moments API fetch completed")
        config.addModule(Modules.momentsAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()

        teal.momentsAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(module == "\(MomentsAPIModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            momentsAPICompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_momentsAPI_wrapper_throws_errors_if_not_added() throws {
        let momentsAPICompleted = expectation(description: "Moments API fetch completed")
        let teal = createTealium()

        teal.momentsAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(module == "\(MomentsAPIModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            momentsAPICompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_momentsAPI_handles_network_error() throws {
        let momentsAPICompleted = expectation(description: "Moments API fetch completed")

        client.result = .failure(.urlError(URLError(.notConnectedToInternet)))

        config.addModule(Modules.momentsAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setRegion(.usEast)
        }))

        let teal = createTealium()

        teal.momentsAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))

            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError(let momentsAPIError) = error,
                      case .networkError = momentsAPIError else {
                    XCTFail("Expected underlyingError with networkError, got \(error)")
                    return
                }
                momentsAPICompleted.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }

    func test_momentsAPI_handles_http_error() throws {
        let momentsAPICompleted = expectation(description: "Moments API fetch completed")

        guard let url = URL(string: "https://example.com"),
              let errorResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil) else {
            XCTFail("Failed to create test URL or response")
            return
        }
        client.result = .success(NetworkResponse(data: Data(), urlResponse: errorResponse))

        config.addModule(Modules.momentsAPI(forcingSettings: { enforcedSettings in
            enforcedSettings.setRegion(.usEast)
        }))

        let teal = createTealium()

        teal.momentsAPI().fetchEngineResponse(engineID: "test-engine").subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))

            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError = error else {
                    XCTFail("Expected underlyingError, got \(error)")
                    return
                }
                momentsAPICompleted.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }
}
