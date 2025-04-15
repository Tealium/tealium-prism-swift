//
//  TraceManagerModuleTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TraceManagerModuleTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let tracker: MockTracker = MockTracker()
    var traceManager: TraceManagerModule!

    override func setUpWithError() throws {
        let dataStoreProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
        let dataStore = try dataStoreProvider.getModuleStore(name: TraceManagerModule.id)
        traceManager = TraceManagerModule(dataStore: dataStore, tracker: tracker)
    }

    func test_killVisitorSession_completes_with_exception_when_not_in_trace() {
        let completesWithException = expectation(description: "Exception expected")
        traceManager.killVisitorSession { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .genericError = error as? TealiumError else {
                    XCTFail("Unexpected error: \(String(describing: error))")
                    return
                }
                completesWithException.fulfill()
            }
        }
        waitForDefaultTimeout()
    }

    func test_killVisitorSession_does_not_track_event_when_not_in_trace() {
        let trackNotCalled = expectation(description: "Track should not be called")
        trackNotCalled.isInverted = true
        _ = tracker.onTrack.subscribeOnce { _ in
            trackNotCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_killVisitorSession_tracks_dispatch_with_trace_id_and_event_name_when_in_trace() throws {
        let dispatchTracked = expectation(description: "Dispatch should be tracked")
        try traceManager.join(id: "12345")
        _ = tracker.onTrack.subscribeOnce { event in
            XCTAssertEqual(event.name, TealiumKey.killVisitorSession)
            XCTAssertEqual(event.eventData.get(key: TealiumDataKey.traceId), "12345")
            XCTAssertEqual(event.eventData.get(key: TealiumDataKey.killVisitorSessionEvent), TealiumKey.killVisitorSession)
            dispatchTracked.fulfill()
        }
        traceManager.killVisitorSession()
        waitForDefaultTimeout()
    }

    func test_killVisitorSession_completes_without_error_when_dispatch_accepted() throws {
        let completedSuccesfully = expectation(description: "Should complete successfully")
        try traceManager.join(id: "12345")
        traceManager.killVisitorSession { result in
            XCTAssertResultIsSuccess(result)
            completedSuccesfully.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_killVisitorSession_completes_with_exception_when_dispatch_dropped() throws {
        let completesWithException = expectation(description: "Exception expected")
        tracker.result = .dropped
        try traceManager.join(id: "12345")
        traceManager.killVisitorSession { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .genericError = error as? TealiumError else {
                    XCTFail("Unexpected error: \(String(describing: error))")
                    return
                }
                completesWithException.fulfill()
            }
        }
        waitForDefaultTimeout()
    }

    func test_collect_returns_trace_id_after_joining_trace() throws {
        try traceManager.join(id: "12345")
        let context = DispatchContext(source: .application, initialData: [:])
        XCTAssertEqual(traceManager.collect(context).get(key: TealiumDataKey.traceId), "12345")
    }

    func test_collect_returns_empty_data_object_after_leaving_trace() throws {
        try traceManager.join(id: "12345")
        try traceManager.leave()
        let context = DispatchContext(source: .application, initialData: [:])
        XCTAssertEqual(traceManager.collect(context).count, 0)
    }

    func test_collect_returns_empty_data_object_when_source_is_trace_manager() throws {
        try traceManager.join(id: "12345")
        let context = DispatchContext(source: .module(TraceManagerModule.self), initialData: [:])
        XCTAssertEqual(traceManager.collect(context).count, 0)
    }
}
