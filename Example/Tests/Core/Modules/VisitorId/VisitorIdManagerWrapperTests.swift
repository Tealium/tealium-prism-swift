//
//  VisitorIdManagerWrapperTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class VisitorIdManagerWrapperTests: VisitorIdManagerWrapperBaseTests {
    override func setUp() {
        super.setUp()
        createModule()
    }

    // MARK: - current / regenerate / eraseLocalHistory when enabled

    func test_current_returns_visitorId_when_enabled() {
        let completed = expectation(description: "current completes")
        wrapper.current().subscribe { result in
            XCTAssertResultIsSuccess(result)
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_regenerate_returns_a_new_visitorId() {
        var firstId: String?
        let firstCompleted = expectation(description: "current completes")
        wrapper.current().subscribe { result in
            XCTAssertResultIsSuccess(result) { id in firstId = id }
            firstCompleted.fulfill()
        }
        waitOnQueue(queue: queue)

        let regenerateCompleted = expectation(description: "regenerate completes")
        wrapper.regenerate().subscribe { result in
            XCTAssertResultIsSuccess(result) { newId in
                XCTAssertNotEqual(newId, firstId)
            }
            regenerateCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_eraseLocalHistory_returns_a_new_visitorId() {
        var firstId: String?
        let firstCompleted = expectation(description: "current completes")
        wrapper.current().subscribe { result in
            XCTAssertResultIsSuccess(result) { id in firstId = id }
            firstCompleted.fulfill()
        }
        waitOnQueue(queue: queue)

        let eraseCompleted = expectation(description: "eraseLocalHistory completes")
        wrapper.eraseLocalHistory().subscribe { result in
            XCTAssertResultIsSuccess(result) { newId in
                XCTAssertNotEqual(newId, firstId)
            }
            eraseCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    // MARK: - Failures when disabled

    func test_current_fails_with_moduleNotEnabled_when_module_disabled() {
        manager.updateSettings(context: sharedContext, settings: settings(enabled: false))
        let completed = expectation(description: "current completes")
        wrapper.current().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let moduleType) = error else {
                    XCTFail("Expected moduleNotEnabled, got \(error)")
                    return
                }
                XCTAssertEqual(moduleType, VisitorIdModule.moduleType)
            }
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_regenerate_fails_with_moduleNotEnabled_when_module_disabled() {
        manager.updateSettings(context: sharedContext, settings: settings(enabled: false))
        let completed = expectation(description: "regenerate completes")
        wrapper.regenerate().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled = error else {
                    XCTFail("Expected moduleNotEnabled, got \(error)")
                    return
                }
            }
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_eraseLocalHistory_fails_with_moduleNotEnabled_when_module_disabled() {
        manager.updateSettings(context: sharedContext, settings: settings(enabled: false))
        let completed = expectation(description: "eraseLocalHistory completes")
        wrapper.eraseLocalHistory().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled = error else {
                    XCTFail("Expected moduleNotEnabled, got \(error)")
                    return
                }
            }
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    // MARK: - Subscription

    func test_subscribe_emits_current_visitorId_then_new_value_on_regenerate_and_eraseLocalHistory() {
        let notified = expectation(description: "Subscriber is notified for initial value, regenerate and eraseLocalHistory")
        notified.expectedFulfillmentCount = 3
        var results: [Result<String, ModuleError<Error>>] = []
        let disposable = wrapper.subscribe { result in
            results.append(result)
            notified.fulfill()
        }
        wrapper.regenerate()
        wrapper.eraseLocalHistory()
        waitOnQueue(queue: queue)
        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertResultIsSuccess(result)
        }
        let visitorIds = results.compactMap { try? $0.get() }
        XCTAssertEqual(Set(visitorIds).count, 3, "Every emission should carry a distinct visitor id")
        disposable.dispose()
    }

    func test_subscribe_emits_new_visitorId_when_a_second_identity_is_set_in_dataLayer() {
        let notified = expectation(description: "Subscriber is notified for initial value and identity switch")
        notified.expectedFulfillmentCount = 2
        var results: [Result<String, ModuleError<Error>>] = []
        let disposable = wrapper.subscribe { result in
            results.append(result)
            notified.fulfill()
        }
        // Enqueued after the subscription, so both writes are observed by an already active subscriber.
        queue.ensureOnQueue {
            // The first identity written only tags the current visitor id owned by no one yet (no id change).
            // A second, different identity is what actually triggers a visitor id switch and a new emission.
            do {
                try self.sharedContext.dataLayer.edit()
                    .put(key: Self.identityKey, value: "identityValue", expiry: .forever)
                    .commit()
                try self.sharedContext.dataLayer.edit()
                    .put(key: Self.identityKey, value: "otherIdentity", expiry: .forever)
                    .commit()
            } catch {
                XCTFail("Failed to write the identity to the data layer: \(error)")
            }
        }
        waitOnQueue(queue: queue)
        guard results.count == 2,
              case .success(let initialVisitorId) = results[0],
              case .success(let switchedVisitorId) = results[1] else {
            XCTFail("Expected two successful emissions, got \(results)")
            return
        }
        XCTAssertNotEqual(initialVisitorId, switchedVisitorId)
        disposable.dispose()
    }

    func test_subscribe_reports_one_failure_when_disabled_then_the_same_visitorId_when_reenabled() {
        let notified = expectation(description: "Subscriber is notified for initial success, disable and re-enable")
        notified.expectedFulfillmentCount = 3
        var results: [Result<String, ModuleError<Error>>] = []
        let disposable = wrapper.subscribe { result in
            results.append(result)
            notified.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.sharedContext, settings: self.settings(enabled: false))
            // A repeated disable pass must not emit a second failure.
            self.manager.updateSettings(context: self.sharedContext, settings: self.settings(enabled: false))
            self.manager.updateSettings(context: self.sharedContext, settings: SDKSettings(self.config.getEnforcedSDKSettings()))
        }
        waitOnQueue(queue: queue)
        // The subscription must not have completed after the failure: a success still arrives afterwards,
        // carrying the persisted visitor id rather than a newly generated one.
        guard results.count == 3,
              case .success(let initialVisitorId) = results[0],
              case .failure = results[1],
              case .success(let reenabledVisitorId) = results[2] else {
            XCTFail("Expected success, failure, success; got \(results)")
            return
        }
        XCTAssertEqual(reenabledVisitorId, initialVisitorId)
        disposable.dispose()
    }

    func test_subscribe_does_not_reemit_when_identical_settings_are_reapplied() {
        let initialNotified = expectation(description: "Subscriber is notified once for the initial value")
        let unexpectedReemission = expectation(description: "No further emission when identical settings are reapplied")
        unexpectedReemission.isInverted = true
        var emissionCount = 0
        let disposable = wrapper.subscribe { _ in
            emissionCount += 1
            if emissionCount == 1 {
                initialNotified.fulfill()
            } else {
                unexpectedReemission.fulfill()
            }
        }
        queue.dispatchQueue.sync {
            wait(for: [initialNotified], timeout: Self.defaultTimeout)
            self.manager.updateSettings(context: self.sharedContext, settings: SDKSettings(self.config.getEnforcedSDKSettings()))
            wait(for: [unexpectedReemission], timeout: Self.defaultTimeout)
        }
        XCTAssertEqual(emissionCount, 1)
        disposable.dispose()
    }

    // MARK: - Tealium instance shutdown

    func test_subscribe_reports_one_tealiumError_then_completes_when_the_instance_shuts_down() {
        let notified = expectation(description: "Subscriber is notified for initial success and shutdown failure")
        notified.expectedFulfillmentCount = 2
        let completed = expectation(description: "Subscription completes after the shutdown failure")
        var results: [Result<String, ModuleError<Error>>] = []
        let disposable = wrapper.subscribe({ result in
            results.append(result)
            notified.fulfill()
        }, onComplete: {
            completed.fulfill()
        })
        queue.ensureOnQueue {
            self.onManager.onNext(.failure(.instanceShutdown))
            self.onManager.onComplete()
        }
        waitOnQueue(queue: queue)
        guard results.count == 2,
              case .success = results[0],
              case .failure(.tealiumError(let error)) = results[1],
              case .instanceShutdown = error else {
            XCTFail("Expected success, then tealiumError(.instanceShutdown); got \(results)")
            return
        }
        disposable.dispose()
    }

    func test_current_fails_with_tealiumError_after_the_instance_shuts_down() {
        let completed = expectation(description: "current completes")
        queue.ensureOnQueue { [onManager] in
            onManager.onNext(.failure(.instanceShutdown))
            onManager.onComplete()
        }
        wrapper.current().subscribe { result in
            guard case .failure(.tealiumError(let error)) = result,
                  case .instanceShutdown = error else {
                XCTFail("Expected tealiumError(.instanceShutdown), got \(result)")
                return
            }
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}
