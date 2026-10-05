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

    func config(account: String = "account",
                profile: String = "profile",
                modules: [any ModuleFactory] = [],
                settingsUrl: String? = nil) -> TealiumConfig {
        TealiumConfig(account: account,
                      profile: profile,
                      environment: "env",
                      modules: modules,
                      settingsFile: nil,
                      settingsUrl: settingsUrl)
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

    func test_create_called_on_shutdown_error_waits_for_previous_implementation_to_be_shut_down() {
        let config = config()
        let teal = manager.create(config: config, completion: { _ in })
        let recreated = expectation(description: "Instance was recreated from the shutdown error subscriber")
        manager.queue.ensureOnQueue {
            guard let previousInstance = self.manager.instances[config.key]?.instance else {
                XCTFail("Expected an implementation to have been created")
                return
            }
            _ = teal.proxy.onObject.subscribe { result in
                guard case .failure(.instanceShutdown) = result else { return }
                _ = self.manager.create(config: config) { result in
                    XCTAssertResultIsSuccess(result)
                    XCTAssertTrue(previousInstance.isShutdown)
                    recreated.fulfill()
                }
            }
            self.manager.shutdown(config.key)
        }
        waitForDefaultTimeout()
    }

    func test_nested_shutdown_of_other_key_and_create_of_same_key_waits_for_previous_implementation_to_be_shut_down() {
        let configA = config(account: "accountA")
        let configB = config(account: "accountB")
        let tealA = manager.create(config: configA, completion: { _ in })
        _ = manager.create(config: configB, completion: { _ in })
        let recreated = expectation(description: "Instance A was recreated from the shutdown error subscriber")
        manager.queue.ensureOnQueue {
            guard let previousInstance = self.manager.instances[configA.key]?.instance,
                  let instanceB = self.manager.instances[configB.key]?.instance else {
                XCTFail("Expected implementations to have been created")
                return
            }
            _ = tealA.proxy.onObject.subscribe { result in
                guard case .failure(.instanceShutdown) = result else { return }
                self.manager.shutdown(configB.key)
                _ = self.manager.create(config: configA) { result in
                    XCTAssertResultIsSuccess(result)
                    XCTAssertTrue(previousInstance.isShutdown)
                    XCTAssertTrue(instanceB.isShutdown)
                    XCTAssertFalse(self.manager.instances[configA.key]?.instance === previousInstance)
                    recreated.fulfill()
                }
            }
            self.manager.shutdown(configA.key)
        }
        waitForDefaultTimeout()
    }

    func test_shutdown_of_stale_tealium_does_not_shut_down_recreated_instance() {
        let config = config()
        let oldTeal = manager.create(config: config, completion: { _ in })
        manager.shutdown(config.key)
        let newTeal = manager.create(config: config, completion: { _ in })
        oldTeal.shutdown()
        assertInstanceIsAlive(config: config, expected: newTeal)
    }

    func test_manager_shutdown_of_stale_tealium_does_not_shut_down_recreated_instance() {
        let config = config()
        let oldTeal = manager.create(config: config, completion: { _ in })
        manager.shutdown(oldTeal)
        let newTeal = manager.create(config: config, completion: { _ in })
        manager.shutdown(oldTeal)
        assertInstanceIsAlive(config: config, expected: newTeal)
    }

    func assertInstanceIsAlive(config: TealiumConfig, expected: Tealium, file: StaticString = #filePath, line: UInt = #line) {
        let checked = expectation(description: "Recreated instance is still alive")
        manager.queue.ensureOnQueue {
            XCTAssertNotNil(self.manager.instances[config.key], file: file, line: line)
            XCTAssertEqual(self.manager.instances[config.key]?.instance.isShutdown, false, file: file, line: line)
            XCTAssertTrue(self.manager.instances[config.key]?.proxy === expected, file: file, line: line)
        }
        expected.track("Event").subscribe { result in
            XCTAssertResultIsSuccess(result, file: file, line: line)
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_shutdown_does_not_forward_to_observeModule_what_the_module_emits_while_shutting_down() {
        let config = config(modules: [MockModule.factory()])
        let teal = manager.create(config: config, completion: { _ in })
        let moduleProxy: ModuleProxy<MockModule, Error> = teal.createModuleProxy()
        let moduleEnabled = expectation(description: "Module is enabled")
        moduleProxy.getModule { module in
            XCTAssertNotNil(module)
            moduleEnabled.fulfill()
        }
        waitForDefaultTimeout()
        let moduleEmittedOnShutdown = expectation(description: "Module emitted while shutting down")
        let emissionForwarded = expectation(description: "Emission forwarded to observeModule")
        emissionForwarded.isInverted = true
        _ = MockModule.onShutdown.subscribeOnce {
            moduleEmittedOnShutdown.fulfill()
        }
        _ = moduleProxy.observeModule { $0.onShutdown }.subscribe {
            emissionForwarded.fulfill()
        }
        manager.shutdown(config.key)
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

    func test_observeModuleResult_receives_only_tealiumError_instanceShutdown_after_shutdown_with_no_preceding_moduleNotEnabled() {
        let config = config(modules: [MockModule.factory()])
        let teal = manager.create(config: config, completion: { _ in })
        let moduleProxy: ModuleProxy<MockModule, Error> = teal.createModuleProxy()
        let firstSuccess = expectation(description: "observeModuleResult emits success while the module is enabled")
        let completedAfterShutdown = expectation(description: "observeModuleResult completes after shutdown")
        var results: [Result<Int, ModuleError<Error>>] = []
        _ = moduleProxy.observeModuleResult { _ in Observables.just(1) }.subscribe({ result in
            results.append(result)
            if results.count == 1 {
                firstSuccess.fulfill()
            }
        }, onComplete: {
            completedAfterShutdown.fulfill()
        })
        wait(for: [firstSuccess], timeout: Self.defaultTimeout)
        manager.shutdown(config.key)
        wait(for: [completedAfterShutdown], timeout: Self.defaultTimeout)
        guard results.count == 2 else {
            XCTFail("Expected 2 results but got \(results)")
            return
        }
        XCTAssertResultIsSuccess(results[0])
        guard case .failure(let secondError) = results[1],
              case .tealiumError(let tealiumError) = secondError,
              case .instanceShutdown = tealiumError else {
            XCTFail("Expected tealiumError(.instanceShutdown) but got \(results[1])")
            return
        }
    }

    func test_instance_observable_completes_after_initialization_failure() {
        let config = config(settingsUrl: "")
        let initializationFailed = expectation(description: "proxy.onObject emits the initialization failure")
        let completed = expectation(description: "proxy.onObject completes after the initialization failure")
        let teal = manager.create(config: config) { result in
            XCTAssertResultIsFailure(result)
        }
        _ = teal.proxy.onObject.subscribe({ result in
            XCTAssertResultIsFailure(result) { error in
                guard case .initializationError = error else {
                    XCTFail("Expected .initializationError but got \(error)")
                    return
                }
            }
            initializationFailed.fulfill()
        }, onComplete: {
            completed.fulfill()
        })
        waitForDefaultTimeout()
    }

    func test_shutdown_by_key_called_on_shutdown_error_after_create_shuts_down_the_recreated_instance() {
        let config = config()
        let teal = manager.create(config: config, completion: { _ in })
        manager.queue.ensureOnQueue {
            _ = teal.proxy.onObject.subscribe { result in
                guard case .failure(.instanceShutdown) = result else { return }
                _ = self.manager.create(config: config, completion: { _ in })
                self.manager.shutdown(config.key)
            }
            self.manager.shutdown(config.key)
        }
        let checked = expectation(description: "No instance remains for the key")
        manager.queue.ensureOnQueue {
            XCTAssertNil(self.manager.instances[config.key])
            checked.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_get_called_on_shutdown_error_after_create_returns_the_recreated_instance() {
        let config = config()
        let teal = manager.create(config: config, completion: { _ in })
        let getCompleted = expectation(description: "Get returned the recreated instance")
        manager.queue.ensureOnQueue {
            _ = teal.proxy.onObject.subscribe { result in
                guard case .failure(.instanceShutdown) = result else { return }
                let recreatedTeal = self.manager.create(config: config, completion: { _ in })
                self.manager.get(config) { fetchedTeal in
                    XCTAssertTrue(fetchedTeal === recreatedTeal)
                    getCompleted.fulfill()
                }
            }
            self.manager.shutdown(config.key)
        }
        waitForDefaultTimeout()
    }
}
