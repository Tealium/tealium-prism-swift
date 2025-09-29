//
//  SessionManagerTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SessionManagerTests: XCTestCase {
    lazy var dispatch = Dispatch(name: "event")
    let databaseProvider = MockDatabaseProvider()
    lazy var moduleRepository = SQLModulesRepository(dbProvider: databaseProvider)
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                 modulesRepository: moduleRepository)
    @StateSubject(5.minutes)
    var sessionTimeout: ObservableState<TimeFrame>

    lazy var sessionManager: SessionManager! = createSessionManager()

    func createSessionManager(debouncer: DebouncerProtocol = Debouncer(queue: .main),
                              timestamp: Int64 = Date().unixTimeMilliseconds) -> SessionManager? {
        do {
            let store = try storeProvider.getModuleStore(name: "core")
            return SessionManager(debouncer: debouncer,
                                  dataStore: store,
                                  moduleRepository: moduleRepository,
                                  sessionTimeout: sessionTimeout,
                                  timestamp: timestamp,
                                  logger: nil)
        } catch {
                XCTFail("Could not create a store: \(error)")
            return nil
        }
    }

    func test_init_does_not_emit_a_session_when_no_existing_session_and_no_events() {
        let sessionReported = expectation(description: "Session is not reported")
        sessionReported.isInverted = true
        sessionManager.session.subscribeOnce { _ in
            sessionReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_init_clears_session_data_when_no_existing_session() throws {
        let store = try storeProvider.getModuleStore(name: "some")
        try store.edit().put(key: "some", value: "value", expiry: .session).commit()
        XCTAssertEqual(store.get(key: "some"), "value")
        _ = sessionManager
        XCTAssertNil(store.getDataItem(key: "some"))
    }

    func test_init_clears_session_data_when_session_expired() throws {
        sessionManager.registerDispatch(&dispatch)

        let store = try storeProvider.getModuleStore(name: "some")
        try store.edit().put(key: "some", value: "value", expiry: .session).commit()
        XCTAssertEqual(store.get(key: "some"), "value")
        sessionManager = createSessionManager(timestamp: 20.minutes.afterNow().unixTimeMilliseconds)
        XCTAssertNil(store.getDataItem(key: "some"))
    }

    func test_init_does_not_clear_session_data_when_session_resumed() throws {
        sessionManager.registerDispatch(&dispatch)

        let store = try storeProvider.getModuleStore(name: "some")
        try store.edit().put(key: "some", value: "value", expiry: .session).commit()
        XCTAssertEqual(store.get(key: "some"), "value")
        sessionManager = createSessionManager()
        XCTAssertEqual(store.get(key: "some"), "value")
    }

    func test_init_resumes_a_session_when_session_not_expired() {
        sessionManager.registerDispatch(&dispatch)

        let sessionReported = expectation(description: "Session is reported")
        sessionManager = createSessionManager()
        sessionManager.session.subscribeOnce { newSession in
            XCTAssertEqual(newSession.status, .resumed)
            sessionReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_init_schedules_expiration_from_last_event_time_when_session_resumed() {
        let threeMinutesAgo = 3.minutes.beforeNow().unixTimeMilliseconds
        let expectedDelay = 5.minutes.inSeconds() - 3.minutes.inSeconds()
        var pastDispatch = Dispatch(payload: [:], id: "1", timestamp: threeMinutesAgo)
        sessionManager.registerDispatch(&pastDispatch)

        let sessionReported = expectation(description: "Session is reported")
        let debouncerCalled = expectation(description: "Debouncer is called")
        let debouncer = MockDebouncer(queue: .main)
        debouncer.onDebounce.subscribeOnce { interval in
            XCTAssertEqual(interval, expectedDelay, accuracy: 10.0)
            debouncerCalled.fulfill()
        }
        sessionManager = createSessionManager(debouncer: debouncer)
        sessionManager.session.subscribeOnce { newSession in
            XCTAssertEqual(newSession.status, .resumed)
            sessionReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_resumed_session_expires() {
        sessionManager.registerDispatch(&dispatch)

        sessionManager = createSessionManager(debouncer: MockDebouncer(queue: .main))

        let sessionReported = expectation(description: "Session is reported twice")
        sessionReported.expectedFulfillmentCount = 2
        var count = 0
        _ = sessionManager.session.subscribe { newSession in
            switch count {
            case 0:
                XCTAssertEqual(newSession.status, .resumed, "On next launch session is resumed")
            case 1:
                XCTAssertEqual(newSession.status, .ended,
                               "MockDebouncer should expire the resumed session immediately")
            default:
                XCTFail("Unexpected count \(count)")
            }
            count += 1
            sessionReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_registerDispatch_starts_a_session() {
        let sessionReported = expectation(description: "Session is reported")
        sessionManager.session.subscribeOnce { _ in
            sessionReported.fulfill()
        }
        sessionManager.registerDispatch(&dispatch)
        waitForDefaultTimeout()
    }

    func test_registerDispatch_ends_a_session_on_subsequent_initializations_if_expired() {
        sessionManager.registerDispatch(&dispatch)
        let sessionReported = expectation(description: "Session is reported")
        sessionManager = createSessionManager(timestamp: 6.minutes.afterNow().unixTimeMilliseconds)
        sessionManager.session.subscribeOnce { newSession in
            XCTAssertEqual(newSession.status, .ended)
            sessionReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_registerDispatch_updates_session() {
        let sessionReported = expectation(description: "Session is reported three times")
        sessionReported.expectedFulfillmentCount = 3

        var reportedSessions = [Session]()
        _ = sessionManager.session.subscribe { newSession in
            reportedSessions.append(newSession)
            XCTAssertEqual(newSession.status, .started)
            XCTAssertEqual(newSession.eventCount, reportedSessions.count)
            for session in reportedSessions {
                XCTAssertEqual(session.sessionId, newSession.sessionId)
            }
            sessionReported.fulfill()
        }
        let timestamp = Date().unixTimeMilliseconds
        var dispatch1 = Dispatch(payload: [:], id: "1", timestamp: timestamp)
        sessionManager.registerDispatch(&dispatch1)
        var dispatch2 = Dispatch(payload: [:], id: "2", timestamp: timestamp + 500)
        sessionManager.registerDispatch(&dispatch2)
        var dispatch3 = Dispatch(payload: [:], id: "3", timestamp: timestamp + 1000)
        sessionManager.registerDispatch(&dispatch3)
        waitForDefaultTimeout()
    }

    func test_registerDispatch_updates_dispatch() {
        sessionManager.registerDispatch(&dispatch)
        let payload = dispatch.payload
        XCTAssertNotNil(payload.getDataItem(key: TealiumDataKey.sessionId))
        XCTAssertTrueOptional(payload.get(key: TealiumDataKey.isNewSession))
        XCTAssertNotNil(payload.getDataItem(key: TealiumDataKey.sessionTimeout))
    }

    func test_subsequent_registerDispatch_doesnt_add_isNewSession() {
        var dispatch1 = Dispatch(name: "event1")
        sessionManager.registerDispatch(&dispatch1)
        var dispatch2 = Dispatch(name: "event2")
        sessionManager.registerDispatch(&dispatch2)
        let payload = dispatch2.payload
        XCTAssertNotNil(payload.getDataItem(key: TealiumDataKey.sessionId))
        XCTAssertNil(payload.getDataItem(key: TealiumDataKey.isNewSession))
        XCTAssertNotNil(payload.getDataItem(key: TealiumDataKey.sessionTimeout))
    }

    func test_registerDispatch_starts_new_session_if_expired() {
        let sessionChanges = expectation(description: "Session changes 4 times")
        sessionChanges.expectedFulfillmentCount = 4
        sessionManager = createSessionManager(debouncer: MockDebouncer(queue: .main))

        var reportedSessions = [Session]()
        _ = sessionManager.session.subscribe { session in
            reportedSessions.append(session)
            switch reportedSessions.count {
            case 1:
                XCTAssertEqual(session.status, .started)
                XCTAssertEqual(session.eventCount, 1)
            case 2:
                XCTAssertEqual(session.status, .ended)
                XCTAssertEqual(session.eventCount, 1)
                XCTAssertEqual(session.sessionId, reportedSessions[0].sessionId)
            case 3:
                XCTAssertEqual(session.status, .started)
                XCTAssertEqual(session.eventCount, 1)
            case 4:
                XCTAssertEqual(session.status, .ended)
                XCTAssertEqual(session.eventCount, 1)
                XCTAssertEqual(session.sessionId, reportedSessions[2].sessionId)
            default:
                XCTFail("Unexpected count \(reportedSessions.count)")
            }
            sessionChanges.fulfill()
        }
        var dispatch1 = Dispatch(name: "event1")
        sessionManager.registerDispatch(&dispatch1)
        var dispatch2 = Dispatch(name: "event2")
        DispatchQueue.main.async {
            self.sessionManager.registerDispatch(&dispatch2)
        }

        waitForDefaultTimeout()
    }

    func test_registerDispatch_schedules_expiry_from_dispatch_timestamp_when_new_session_started() {
        let threeMinutesAgo = 3.minutes.beforeNow().unixTimeMilliseconds
        let expectedDelay = 5.minutes.inSeconds() - 3.minutes.inSeconds()
        var pastDispatch = Dispatch(payload: [:], id: "1", timestamp: threeMinutesAgo)
        let sessionReported = expectation(description: "Session is reported")
        let debouncerCalled = expectation(description: "Debouncer is called")
        let debouncer = MockDebouncer(queue: .main)
        debouncer.onDebounce.subscribeOnce { interval in
            XCTAssertEqual(interval, expectedDelay, accuracy: 10.0)
            debouncerCalled.fulfill()
        }
        sessionManager = createSessionManager(debouncer: debouncer)
        sessionManager.registerDispatch(&pastDispatch)
        sessionManager.session.subscribeOnce { newSession in
            XCTAssertEqual(newSession.status, .started)
            sessionReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_registerDispatch_schedules_expiry_from_dispatch_timestamp_when_extending_a_session() {
        let sessionReported = expectation(description: "Session is reported three times")
        sessionReported.expectedFulfillmentCount = 3
        let debouncerCalled = expectation(description: "Debouncer is called twice")
        debouncerCalled.expectedFulfillmentCount = 2
        let debouncer = MockDebouncer(queue: .main)
        sessionManager = createSessionManager(debouncer: debouncer)

        let now = Date().unixTimeMilliseconds
        let expectedDelay = 5.minutes.inSeconds() + 3.minutes.inSeconds()
        let threeMinutesHereafter = now + 3.minutes.inMilliseconds()
        var count = 0
        _ = debouncer.onDebounce.subscribe { interval in
            if count == 0 {
                XCTAssertEqual(interval, 5.minutes.inSeconds(), accuracy: 10.0)
            } else {
                XCTAssertEqual(interval, expectedDelay, accuracy: 10.0)
            }
            count += 1
            debouncerCalled.fulfill()
        }
        _ = sessionManager.session.subscribe { _ in
            sessionReported.fulfill()
        }

        var dispatch = Dispatch(payload: [:], id: "1", timestamp: now)
        sessionManager.registerDispatch(&dispatch)
        var futureDispatch = Dispatch(payload: [:], id: "1", timestamp: threeMinutesHereafter)
        sessionManager.registerDispatch(&futureDispatch)

        waitForDefaultTimeout()
    }
}
