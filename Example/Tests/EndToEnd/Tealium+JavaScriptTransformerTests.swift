//
//  Tealium+JavaScriptTransformerTests.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumJavaScriptTransformerTests: TealiumBaseTests {

    override func setUp() {
        super.setUp()
        config.addModule(MockDispatcher.factory())
    }

    private func setTransformation(jsCode: String) {
        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "test-transform")
                .setJsCode(jsCode)
                .setScope(.afterCollectors)
        )
    }

    func test_jstransformer_mutates_dispatch_payload() {
        setTransformation(jsCode: "payload.added_key = 'added_value'")
        let teal = createTealium()
        let dispatched = expectation(description: "Dispatch arrives with mutated payload")
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.first?.payload.get(key: "added_key"), "added_value")
            dispatched.fulfill()
        }
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_jstransformer_track_in_js_triggers_additional_dispatch() {
        setTransformation(jsCode: "track('js_event')")
        let teal = createTealium()
        let originalDispatched = expectation(description: "Original event dispatched")
        let jsDispatched = expectation(description: "JS-triggered event dispatched with js_tracking flag")
        MockDispatcher.onDispatch.subscribe { dispatches in
            guard let dispatch = dispatches.first else { return }
            if dispatch.name == "Event" {
                originalDispatched.fulfill()
            } else if dispatch.name == "js_event" {
                let jsTracking: Bool? = dispatch.payload.get(key: "js_tracking")
                XCTAssertEqual(jsTracking, true)
                jsDispatched.fulfill()
            }
        }.addTo(disposer)
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_jstransformer_track_in_js_does_not_cause_recursion() {
        setTransformation(jsCode: "track('secondary_event')")
        let teal = createTealium()
        let secondaryDispatched = expectation(description: "Secondary JS event dispatched once")
        let recursionDetected = expectation(description: "No further recursive dispatch")
        recursionDetected.isInverted = true
        var secondaryCount = 0
        MockDispatcher.onDispatch.subscribe { dispatches in
            for dispatch in dispatches where dispatch.name == "secondary_event" {
                secondaryCount += 1
                if secondaryCount == 1 {
                    secondaryDispatched.fulfill()
                } else {
                    recursionDetected.fulfill()
                }
            }
        }.addTo(disposer)
        teal.track("Event")
        waitForExpectations(timeout: 1.0)
    }
}
