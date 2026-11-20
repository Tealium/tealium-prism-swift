//
//  XCTestCase+TealiumInstance.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

extension XCTestCase {
    /// Shuts `tealium` down and returns once the worker queue has handled it, so that the next instance starts after it.
    func shutDownAndWait(_ tealium: Tealium, in manager: TealiumInstanceManager) {
        manager.shutdown(tealium)
        TealiumQueue.worker.dispatchQueue.sync { }
    }

    /// Creates an instance of `config` in `manager`, and returns once the create completes.
    func createResult(config: TealiumConfig, in manager: TealiumInstanceManager) -> InitializationResult<Tealium> {
        var result: InitializationResult<Tealium>?
        let completed = expectation(description: "The create completes")
        _ = manager.create(config: config) {
            result = $0
            completed.fulfill()
        }
        wait(for: [completed], timeout: Self.longTimeout)
        return result ?? .failure(CreateTimedOut())
    }

    /// Creates an instance of `config` in `manager`, and returns the error that the create fails with.
    func createExpectingFailure(config: TealiumConfig, in manager: TealiumInstanceManager) throws -> Error {
        try XCTUnwrapThrownError { try createResult(config: config, in: manager).get() }
    }

    func createExpectingSuccess(config: TealiumConfig, in manager: TealiumInstanceManager) throws -> Tealium {
        try createResult(config: config, in: manager).get()
    }

    /// Tracks `event` on `tealium` and waits until `MockDispatcher` dispatches it.
    func trackAndWaitForDispatch(_ tealium: Tealium, event: String) throws {
        let dispatched = expectation(description: "\(event) is dispatched")
        let subscription = MockDispatcher.onDispatch.subscribe { dispatches in
            if dispatches.contains(where: { $0.name == event }) {
                dispatched.fulfill()
            }
        }
        tealium.track(event)
        wait(for: [dispatched], timeout: Self.longTimeout)
        subscription.dispose()
    }
}

/// The result of a create that never completed, after the failed wait has already been reported.
private struct CreateTimedOut: Error { }
