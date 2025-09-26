//
//  TraceModuleTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TraceModuleTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var dataStoreProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
    let tracker: MockTracker = MockTracker()
    var traceManager: TraceModule!

    override func setUpWithError() throws {
        let dataStore = try dataStoreProvider.getModuleStore(name: TraceModule.moduleType)
        traceManager = TraceModule(dataStore: dataStore, tracker: tracker)
    }

    func test_the_module_id_is_correct() {
        XCTAssertNotNil(dataStoreProvider.modulesRepository.getModules()[TraceModule.moduleType])
    }

    func test_killVisitorSession_throws_an_error_when_not_in_trace() {
        XCTAssertThrowsError(try traceManager.killVisitorSession())
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
            XCTAssertEqual(event.name, TealiumConstants.killVisitorSessionQueryParam)
            XCTAssertEqual(event.payload.get(key: TealiumDataKey.traceId), "12345")
            XCTAssertEqual(event.payload.get(key: TealiumDataKey.killVisitorSessionEvent), TealiumConstants.killVisitorSessionQueryParam)
            dispatchTracked.fulfill()
        }
        try traceManager.killVisitorSession()
        waitForDefaultTimeout()
    }

    func test_killVisitorSession_completes_without_error_when_dispatch_accepted() throws {
        let completedSuccessfully = expectation(description: "Should complete successfully")
        try traceManager.join(id: "12345")
        try traceManager.killVisitorSession { result in
            XCTAssertTrackResultIsAccepted(result)
            completedSuccessfully.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_killVisitorSession_completes_with_dropped_when_dispatch_dropped() throws {
        let completesWithDropped = expectation(description: "Exception expected")
        tracker.acceptTrack = false
        try traceManager.join(id: "12345")
        try traceManager.killVisitorSession { result in
            XCTAssertTrackResultIsDropped(result)
            completesWithDropped.fulfill()
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
        let context = DispatchContext(source: .module(TraceModule.self), initialData: [:])
        XCTAssertEqual(traceManager.collect(context).count, 0)
    }
}
