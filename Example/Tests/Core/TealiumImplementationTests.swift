//
//  TealiumImplementationTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 09/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumImplementationTests: XCTestCase {

    @StateSubject([])
    var modules: ObservableState<[TealiumModule]>

    func test_queueProcessors_doesnt_emit_when_modules_empty() {
        let queueProcessorsDoesntEmit = expectation(description: "QueueProcessors doesn't emit for empty modules")
        queueProcessorsDoesntEmit.isInverted = true
        TealiumImpl.queueProcessors(from: modules)
            .subscribeOnce { _ in
                queueProcessorsDoesntEmit.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_emits_all_dispatchers() {
        _modules.value = [MockDispatcher1(), MockDispatcher2()]
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: modules)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, self.modules.value.map { $0.id })
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_skips_all_non_dispatchers() {
        _modules.value = [MockDispatcher1(), MockDispatcher2(), MockModule()]
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: modules)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, self.modules.value.prefix(2).map { $0.id })
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_emits_consent_manager() {
        _modules.value = [MockDispatcher1(), MockDispatcher2(), MockConsentManager()]
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: modules)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, self.modules.value.map { $0.id })
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_mappingsFromSettings_transforms_object_to_TransformationSettings() throws {
        let settings = StateSubject(SDKSettings(modules: [
            MockModule.id: ["mappings": try DataItem(serializing: [
                [
                    "destination": ["variable": "key"],
                    "parameters": ["key": ["variable": "key"]]
                ]
            ])]
        ]))
        let transformationsMap = TealiumImpl.mappings(from: settings.toStatefulObservable()).value
        guard let transformation = transformationsMap[MockModule.id] else {
            XCTFail("Failed to transform the mappings into a TransformationSettings")
            return
        }
        XCTAssertEqual(transformation.id, "\(MockModule.id)-mapping")
        XCTAssertEqual(transformation.transformerId, "JsonTransformer")
        XCTAssertEqual(transformation.scopes, [.dispatcher(MockModule.id)])
        XCTAssertEqual(transformation.configuration, [
            "operations_type": "map",
            "operations": try DataItem(serializing: [
                [
                    "destination": ["variable": "key"],
                    "parameters": ["key": ["variable": "key"]]
                ]
            ])
        ])
    }
}
