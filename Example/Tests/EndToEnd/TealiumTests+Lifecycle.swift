//
//  TealiumTests+Lifecycle.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumTestsLifecycle: TealiumBaseTests {
    func test_lifecycle_wrapper_works_on_our_queue() throws {
        let lifecycleEventCompleted = expectation(description: "Lifecycle event completed")
        config.addModule(Modules.lifecycle(forcingSettings: { enforcedSettings in
            enforcedSettings.setAutoTrackingEnabled(false)
        }))
        let teal = createTealium()
        teal.lifecycle().launch().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            lifecycleEventCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_lifecycle_wrapper_throws_errors_if_not_enabled() throws {
        let lifecycleEventCompleted = expectation(description: "Lifecycle event completed")
        config.addModule(Modules.lifecycle(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()
        teal.lifecycle().launch().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .objectNotFound(let object) = error as? TealiumError else {
                    XCTFail("Error should be objectNotFound, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == LifecycleModule.self)
            }
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            lifecycleEventCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_lifecycle_wrapper_throws_errors_if_not_added() throws {
        let lifecycleEventCompleted = expectation(description: "Lifecycle event completed")
        let teal = createTealium()
        teal.lifecycle().launch().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .objectNotFound(let object) = error as? TealiumError else {
                    XCTFail("Error should be objectNotFound, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == LifecycleModule.self)
            }
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            lifecycleEventCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }
}
