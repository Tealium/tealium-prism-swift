//
//  TealiumInstanceManagerTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumInstanceManagerTests: XCTestCase {
    let manager = TealiumInstanceManager(queue: .main)

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
        waitForDefaultTimeout()
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
        waitForDefaultTimeout()
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

    func test_create_with_same_config_shares_same_implementation() {
        let config = config()
        _ = manager.create(config: config, completion: { _ in })
        _ = manager.create(config: config, completion: { _ in })
        let checked = expectation(description: "Implementations were checked")
        manager.queue.ensureOnQueue {
            XCTAssertEqual(self.manager.instances.count, 1)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_create_with_different_config_account_uses_different_implementation() {
        _ = manager.create(config: config(account: "account"), completion: { _ in })
        _ = manager.create(config: config(account: "other"), completion: { _ in })
        let checked = expectation(description: "Implementations were checked")
        manager.queue.ensureOnQueue {
            XCTAssertEqual(self.manager.instances.count, 2)
            let impl1 = self.manager.instances["account-profile"]?.instance
            let impl2 = self.manager.instances["other-profile"]?.instance
            XCTAssertNotIdentical(impl1, impl2)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_create_with_different_config_profile_uses_different_implementation() {
        _ = manager.create(config: config(profile: "profile"), completion: { _ in })
        _ = manager.create(config: config(profile: "other"), completion: { _ in })
        let checked = expectation(description: "Implementations were checked")
        manager.queue.ensureOnQueue {
            XCTAssertEqual(self.manager.instances.count, 2)
            let impl1 = self.manager.instances["account-profile"]?.instance
            let impl2 = self.manager.instances["account-other"]?.instance
            XCTAssertNotIdentical(impl1, impl2)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_get_completes_with_nil_if_instance_is_not_previously_created() {
        let getCompleted = expectation(description: "Get is returned")
        manager.get(config()) { teal in
            XCTAssertNil(teal)
            getCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_get_completes_with_previous_tealium_instance_if_created_for_that_config() {
        let getCompleted = expectation(description: "Get is returned")
        let config = config()
        let teal1 = manager.create(config: config, completion: { _ in })
        manager.get(config) { teal2 in
            XCTAssertIdentical(teal1, teal2)
            getCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_instance_stays_alive_after_dropping_local_reference() {
        let creationCompleted = expectation(description: "Instance was created")
        let config = config()
        var teal: Tealium? = manager.create(config: config, completion: { _ in
            creationCompleted.fulfill()
        })
        #if compiler(>=6.2.3)
        weak let weakTeal = teal
        #else
        weak var weakTeal = teal
        #endif
        waitForDefaultTimeout()
        teal = nil
        // The manager retains the instance strongly, so it survives even after we drop our reference.
        XCTAssertNotNil(weakTeal)
        let getCompleted = expectation(description: "Instance still returned after dropping local reference")
        manager.get(config) { teal in
            XCTAssertNotNil(teal)
            getCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_shutdown_by_key_removes_instance() {
        let config = config()
        _ = manager.create(config: config, completion: { _ in })
        let checked = expectation(description: "Instance was removed")
        manager.shutdown(config.key)
        manager.queue.ensureOnQueue {
            XCTAssertTrue(self.manager.instances.isEmpty)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_shutdown_by_tealium_removes_instance() {
        let config = config()
        let teal = manager.create(config: config, completion: { _ in })
        let checked = expectation(description: "Instance was removed")
        manager.shutdown(teal)
        manager.queue.ensureOnQueue {
            XCTAssertTrue(self.manager.instances.isEmpty)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_shutdown_shuts_down_the_implementation() {
        let config = config()
        _ = manager.create(config: config, completion: { _ in })
        let instanceFetched = expectation(description: "Implementation fetched from instances")
        var instance: TealiumImpl?
        manager.queue.ensureOnQueue {
            instance = self.manager.instances[config.key]?.instance
            instanceFetched.fulfill()
        }
        waitForDefaultTimeout()
        guard let instance else { XCTFail("Expected an implementation to have been created"); return }
        XCTAssertFalse(instance.isShutdown)
        manager.shutdown(config.key)
        let checked = expectation(description: "Instance was shut down")
        manager.queue.ensureOnQueue {
            XCTAssertTrue(instance.isShutdown)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_get_after_shutdown_returns_nil() {
        let config = config()
        _ = manager.create(config: config, completion: { _ in })
        manager.shutdown(config.key)
        let getCompleted = expectation(description: "Get returns nil after shutdown")
        manager.get(config) { teal in
            XCTAssertNil(teal)
            getCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_track_after_shutdown_fails_with_instanceShutdown() {
        let config = config()
        let teal = manager.create(config: config, completion: { _ in })
        manager.shutdown(config.key)
        let trackCompleted = expectation(description: "Track completed")
        teal.track("Event").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .instanceShutdown = error else {
                    XCTFail("Expected .instanceShutdown but got \(error)")
                    return
                }
            }
            trackCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_both_proxies_with_same_config_fail_with_instanceShutdown_after_shutdown() {
        let config = config()
        let teal1 = manager.create(config: config, completion: { _ in })
        let teal2 = manager.create(config: config, completion: { _ in })
        manager.shutdown(config.key)
        let tracksCompleted = expectation(description: "Both tracks completed")
        tracksCompleted.expectedFulfillmentCount = 2
        for teal in [teal1, teal2] {
            teal.track("Event").subscribe { result in
                XCTAssertResultIsFailure(result) { error in
                    guard case .instanceShutdown = error else {
                        XCTFail("Expected .instanceShutdown but got \(error)")
                        return
                    }
                }
                tracksCompleted.fulfill()
            }
        }
        waitForDefaultTimeout()
    }

    func test_create_with_same_config_after_shutdown_succeeds() {
        let config = config()
        _ = manager.create(config: config, completion: { _ in })
        manager.shutdown(config.key)
        let creationCompleted = expectation(description: "Instance was recreated after shutdown")
        _ = manager.create(config: config) { result in
            XCTAssertResultIsSuccess(result)
            creationCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_tealium_shutdown_delegates_to_creating_manager() {
        let config = config()
        let teal = manager.create(config: config, completion: { _ in })
        teal.shutdown()
        let checked = expectation(description: "Instance was removed")
        manager.queue.ensureOnQueue {
            XCTAssertTrue(self.manager.instances.isEmpty)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }
}
