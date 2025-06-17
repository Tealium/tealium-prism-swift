//
//  TealiumInstanceManagerTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumInstanceManagerTests: XCTestCase {
    let manager = TealiumInstanceManager.shared

    func config(account: String = "account", profile: String = "profile") -> TealiumConfig {
        TealiumConfig(account: account,
                      profile: profile,
                      environment: "env",
                      modules: [],
                      settingsFile: nil,
                      settingsUrl: nil)
    }

    func test_create_completes_with_success() {
        let creationCompleted = expectation(description: "Instance was created")
        _ = manager.create(config: config()) { result in
            XCTAssertResultIsSuccess(result)
            creationCompleted.fulfill()
        }
        waitOnQueue(queue: manager.queue)
    }

    func test_create_with_same_config_completes_with_success() {
        let creationCompleted = expectation(description: "Instances were created")
        creationCompleted.expectedFulfillmentCount = 2
        _ = manager.create(config: config()) { result in
            XCTAssertResultIsSuccess(result)
            creationCompleted.fulfill()
        }
        _ = manager.create(config: config()) { result in
            XCTAssertResultIsSuccess(result)
            creationCompleted.fulfill()
        }
        waitOnQueue(queue: manager.queue)
    }

    func test_create_with_same_config_returns_different_tealium_instances() {
        let teal1 = manager.create(config: config()) { result in
            XCTAssertResultIsSuccess(result)
        }
        let teal2 = manager.create(config: config()) { result in
            XCTAssertResultIsSuccess(result)
        }
        XCTAssertNotIdentical(teal1, teal2)
    }

    func test_createImplementation_with_same_config_returns_same_implementation() {
        let creationCompleted = expectation(description: "Instances were created")
        let onImplementation1 = manager.createImplementation(config: config())
        let onImplemnetation2 = manager.createImplementation(config: config())
        _ = onImplementation1.combineLatest(onImplemnetation2)
            .subscribeOn(manager.queue)
            .subscribe { result1, result2 in
                XCTAssertResultIsSuccess(result1) { implementation1 in
                    XCTAssertResultIsSuccess(result2) { implementation2 in
                        XCTAssertIdentical(implementation1, implementation2)
                    }
                }
                creationCompleted.fulfill()
            }
        waitOnQueue(queue: manager.queue)
    }

    func test_get_completes_with_nil_if_instance_is_not_previously_created() {
        let getCompleted = expectation(description: "Get is returned")
        manager.get(config()) { teal in
            XCTAssertNil(teal)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: manager.queue)
    }

    func test_get_completes_with_previous_tealium_instance_if_created_for_that_config() {
        let getCompleted = expectation(description: "Get is returned")
        let config = config()
        let teal1 = manager.create(config: config, completion: { _ in })
        manager.get(config) { teal2 in
            XCTAssertIdentical(teal1, teal2)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: manager.queue)
    }

    func test_tealium_proxies_denitialize_when_no_external_reference_are_kept_alive() {
        let creationCompleted = expectation(description: "Instance was created")
        let config = config()
        var teal: Tealium? = manager.create(config: config, completion: { _ in
            creationCompleted.fulfill()
        })
        weak var weakTeal = teal
        manager.queue.dispatchQueue.sync {
            waitForDefaultTimeout()
            XCTAssertNotNil(manager.proxies[config.key]?.value)
            XCTAssertNotNil(weakTeal)
            teal = nil
            XCTAssertNil(manager.proxies[config.key]?.value)
            XCTAssertNil(weakTeal)
        }
    }
}
