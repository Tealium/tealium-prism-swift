//
//  TealiumImplementationTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 09/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumImplementationTests: XCTestCase {

    @StateSubject([])
    var modules: ObservableState<[Module]>

    func test_queueProcessors_doesnt_emit_when_modules_empty() {
        let queueProcessorsDoesntEmit = expectation(description: "QueueProcessors doesn't emit for empty modules")
        queueProcessorsDoesntEmit.isInverted = true
        TealiumImpl.queueProcessors(from: modules, addingConsent: false)
            .subscribeOnce { _ in
                queueProcessorsDoesntEmit.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_emits_all_dispatchers() {
        _modules.value = [MockDispatcher1(), MockDispatcher2()]
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: modules, addingConsent: false)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, self.modules.value.map { $0.id })
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_skips_all_non_dispatchers() {
        _modules.value = [MockDispatcher1(), MockDispatcher2(), MockModule()]
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: modules, addingConsent: false)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, self.modules.value.prefix(2).map { $0.id })
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_emits_consent_manager() {
        _modules.value = [MockDispatcher1(), MockDispatcher2()]
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: modules, addingConsent: true)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, self.modules.value.map { $0.id } + ["consent"])
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }
}
