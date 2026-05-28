//
//  JavaScriptTransformerTests.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class JavaScriptTransformerTests: XCTestCase {

    let databaseProvider = MockDatabaseProvider()
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                 modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
    let mockTracker = MockTracker()
    let mockLogger = MockLogger()
    var dataLayer: (any DataStore)!
    var transformer: JavaScriptTransformer!

    override func setUpWithError() throws {
        dataLayer = try storeProvider.getModuleStore(name: "testJSTransformer")
        transformer = JavaScriptTransformer(tracker: mockTracker,
                                            dataLayer: dataLayer,
                                            logger: mockLogger)
    }

    // MARK: - Identity

    func test_id() {
        XCTAssertEqual(transformer.id, Modules.Types.javaScriptTransformer)
    }

    func test_version() {
        XCTAssertEqual(transformer.version, TealiumConstants.libraryVersion)
    }

    // MARK: - Passthrough / Missing Config

    func test_applyTransformation_with_missing_js_code_completes_with_original_dispatch() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = TransformationSettings(
            id: "test",
            transformerId: Modules.Types.javaScriptTransformer,
            scope: .afterCollectors,
            configuration: [:]
        )
        let expectation = expectation(description: "Completes with original dispatch")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload, dispatch.payload)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_with_blank_js_code_completes_with_original_dispatch() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: " ")
        let expectation = expectation(description: "Completes with original dispatch")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "key"), "value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Payload Mutation

    func test_applyTransformation_adds_new_key_to_payload() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "payload.new_key = 'added'")
        let expectation = expectation(description: "New key added")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "new_key"), "added")
            XCTAssertEqual(result?.payload.get(key: "key"), "value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_modifies_existing_key() {
        let dispatch = Dispatch(name: "test", data: ["key": "original"])
        let settings = buildSettings(jsCode: "payload.key = 'modified'")
        let expectation = expectation(description: "Key modified")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "key"), "modified")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_removes_key_from_payload() {
        let dispatch = Dispatch(name: "test", data: ["key": "value", "remove_me": "gone"])
        let settings = buildSettings(jsCode: "delete payload.remove_me")
        let expectation = expectation(description: "Key removed")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNil(result?.payload.getDataItem(key: "remove_me"))
            XCTAssertEqual(result?.payload.get(key: "key"), "value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Drop

    func test_applyTransformation_drop_returns_nil() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "drop()")
        let expectation = expectation(description: "Dispatch dropped")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNil(result)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Error Handling

    func test_applyTransformation_with_js_error_completes_with_original_dispatch() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "throw new Error('test error')")
        let expectation = expectation(description: "Returns original dispatch with js_error")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "key"), "value")
            XCTAssertNotNil(result?.payload.getDataItem(key: "js_error"))
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Logging

    func test_applyTransformation_js_error_is_logged() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "throw new Error('test error')")
        let logExpectation = expectation(description: "Error is logged")
        mockLogger.handler.onLogged.subscribeOnce { event in
            XCTAssertEqual(event.level, .error)
            XCTAssertTrue(event.message.contains("test error"))
            logExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_console_warn_is_logged_at_warn_level() {
        let dispatch = Dispatch(name: "test", data: [:])
        let settings = buildSettings(jsCode: "console.warn('something went wrong')")
        let logExpectation = expectation(description: "Console warn is logged")
        mockLogger.handler.onLogged.subscribeOnce { event in
            XCTAssertEqual(event.level, .warn)
            XCTAssertEqual(event.message, "something went wrong")
            logExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Scope

    func test_applyTransformation_passes_scope_to_js() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "payload.s = scope")
        let expectation = expectation(description: "Scope passed to JS")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "s"), DispatchScope.afterCollectors.rawValue)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Dispatch Identity Preservation

    func test_applyTransformation_preserves_dispatch_id_and_timestamp() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "payload.new_key = 'added'")
        let expectation = expectation(description: "ID and timestamp preserved")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.id, dispatch.id)
            XCTAssertEqual(result?.timestamp, dispatch.timestamp)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Track from JS

    func test_applyTransformation_track_sets_js_tracking_flag() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "track('js_event', 'event', {})")
        let trackExpectation = expectation(description: "Track received")
        mockTracker.onTrack.subscribeOnce { tracked in
            let jsTracking: Bool? = tracked.payload.get(key: "js_tracking")
            XCTAssertEqual(jsTracking, true)
            XCTAssertEqual(tracked.name, "js_event")
            trackExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_track_with_event_only() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "track('simple_event')")
        let trackExpectation = expectation(description: "Track received with event only")
        mockTracker.onTrack.subscribeOnce { tracked in
            XCTAssertEqual(tracked.name, "simple_event")
            trackExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_track_with_event_and_type() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "track('typed_event', 'view')")
        let trackExpectation = expectation(description: "Track received with event and type")
        mockTracker.onTrack.subscribeOnce { tracked in
            XCTAssertEqual(tracked.name, "typed_event")
            let eventType: String? = tracked.payload.get(key: TealiumDataKey.eventType)
            XCTAssertEqual(eventType, DispatchType.view.rawValue)
            trackExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_track_with_event_type_and_payload() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "track('full_event', 'view', {page: 'home'})")
        let trackExpectation = expectation(description: "Track received with event, type, and payload")
        mockTracker.onTrack.subscribeOnce { tracked in
            XCTAssertEqual(tracked.name, "full_event")
            let eventType: String? = tracked.payload.get(key: TealiumDataKey.eventType)
            XCTAssertEqual(eventType, DispatchType.view.rawValue)
            XCTAssertEqual(tracked.payload.get(key: "page"), "home")
            trackExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_track_with_object_second_arg_treats_it_as_payload() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "track('obj_event', {custom_key: 'custom_value'})")
        let trackExpectation = expectation(description: "Track received with payload as second arg")
        mockTracker.onTrack.subscribeOnce { tracked in
            XCTAssertEqual(tracked.name, "obj_event")
            XCTAssertEqual(tracked.payload.get(key: "custom_key"), "custom_value")
            trackExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { _ in
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_track_suppressed_for_recursive_dispatch() {
        var dispatch = Dispatch(name: "test", data: ["key": "value"])
        dispatch.enrich(data: ["js_tracking": true])
        let settings = buildSettings(jsCode: "track('recursive_event', 'event', {})")
        let trackExpectation = expectation(description: "Track should not be called")
        trackExpectation.isInverted = true
        mockTracker.onTrack.subscribeOnce { _ in
            trackExpectation.fulfill()
        }
        let completionExpectation = expectation(description: "Transformation completes")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNotNil(result)
            completionExpectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - DataLayer

    func test_applyTransformation_dataLayer_put_and_get() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: """
            dataLayer.put('test_key', 'test_value', 0)
            payload.retrieved = dataLayer.get('test_key')
            """)
        let expectation = expectation(description: "DataLayer put and get")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertEqual(result?.payload.get(key: "retrieved"), "test_value")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_dataLayer_remove() {
        try? dataLayer.edit().put(key: "existing_key", value: "existing_value", expiry: .forever).commit()
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: """
            dataLayer.remove('existing_key')
            payload.after_remove = dataLayer.get('existing_key')
            """)
        let expectation = expectation(description: "DataLayer remove")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            XCTAssertNSNull(result?.payload.getDataItem(key: "after_remove")?.toDataInput())
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_applyTransformation_dataLayer_clear() {
        try? dataLayer.edit().put(key: "key1", value: "val1", expiry: .forever).commit()
        try? dataLayer.edit().put(key: "key2", value: "val2", expiry: .forever).commit()
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: """
            dataLayer.clear()
            payload.after_clear = JSON.stringify(dataLayer.getAll())
            """)
        let expectation = expectation(description: "DataLayer clear")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            let afterClear: String? = result?.payload.get(key: "after_clear")
            XCTAssertEqual(afterClear, "{}")
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Expiry Constants

    func test_applyTransformation_expiry_constants_have_correct_sentinel_values() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: """
            payload.forever = Expiry.forever
            payload.session = Expiry.session
            payload.untilRestart = Expiry.untilRestart
            """)
        let expectation = expectation(description: "Expiry constants have correct sentinel values")
        transformer.applyTransformation(settings, to: dispatch, scope: .afterCollectors) { result in
            let forever: Int64? = result?.payload.get(key: "forever")
            let session: Int64? = result?.payload.get(key: "session")
            let untilRestart: Int64? = result?.payload.get(key: "untilRestart")
            XCTAssertEqual(forever, -1)
            XCTAssertEqual(session, -2)
            XCTAssertEqual(untilRestart, -3)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Scope Escaping

    func test_applyTransformation_with_special_characters_in_scope_does_not_break_js() {
        let dispatch = Dispatch(name: "test", data: ["key": "value"])
        let settings = buildSettings(jsCode: "payload.s = scope")
        let scopeId = "quote\"and\\backslash\nnewline\rcarriage\u{2028}ls\u{2029}ps"
        let scope = DispatchScope.dispatcher(id: scopeId)
        let expectation = expectation(description: "Malformed scope string is escaped")
        transformer.applyTransformation(settings, to: dispatch, scope: scope) { result in
            XCTAssertEqual(result?.payload.get(key: "s"), scopeId)
            expectation.fulfill()
        }
        waitForDefaultTimeout()
    }

    // MARK: - Helpers

    private func buildSettings(jsCode: String) -> TransformationSettings {
        let settings = JavaScriptTransformationSettingsBuilder(id: "test")
            .setJsCode(jsCode)
            .setScope(.afterCollectors)
            .build()
        let config = settings.getDataDictionary(key: TransformationSettings.Keys.configuration)?.toDataObject() ?? [:]
        return TransformationSettings(id: "test",
                                      transformerId: Modules.Types.javaScriptTransformer,
                                      scope: .afterCollectors,
                                      configuration: config)
    }
}
