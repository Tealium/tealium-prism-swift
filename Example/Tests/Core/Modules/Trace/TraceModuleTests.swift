//
//  TraceModuleTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TraceModuleTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var dataStoreProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
    let tracker: MockTracker = MockTracker()
    var traceModule: TraceModule!
    let errorSubject = BasePublisher<ErrorEvent>()
    func createTrace(trackErrors: Bool = false, onErrorEvent: Observable<ErrorEvent>? = nil) throws -> TraceModule {
        let dataStore = try dataStoreProvider.getModuleStore(name: TraceModule.moduleType)
        return TraceModule(dataStore: dataStore,
                           tracker: tracker,
                           configuration: TraceModuleConfiguration(trackErrors: trackErrors),
                           onErrorEvent: onErrorEvent ?? errorSubject.asObservable())
    }

    override func setUpWithError() throws {
        traceModule = try createTrace()
    }

    func test_error_tracking_creates_error_dispatch_when_enabled_and_in_trace() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        let errorDispatchTracked = expectation(description: "Error dispatch should be tracked")
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                XCTAssertEqual(event.payload.get(key: "error_description", as: String.self), "TestCategory: Test error")
                errorDispatchTracked.fulfill()
            }
        }
        try traceModule.join(id: "test-trace")
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Test error" }))
        waitForDefaultTimeout()
    }

    func test_error_tracking_doesnt_create_error_dispatch_when_disabled_by_default() throws {
        traceModule = try createTrace(onErrorEvent: errorSubject.asObservable())
        let errorDispatchTracked = expectation(description: "Error dispatch should be tracked")
        errorDispatchTracked.isInverted = true
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorDispatchTracked.fulfill()
            }
        }
        try traceModule.join(id: "test-trace")
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Test error" }))
        waitForDefaultTimeout()
    }

    func test_error_tracking_doesnt_create_error_dispatch_when_enabled_but_not_in_trace() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        let errorDispatchNotTracked = expectation(description: "Error dispatch should not be tracked when not in trace")
        errorDispatchNotTracked.isInverted = true
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorDispatchNotTracked.fulfill()
            }
        }
        // Note: NOT calling join() here - this is the key difference
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Test error" }))
        waitForDefaultTimeout()
    }

    func test_error_tracking_stops_when_leaving_trace() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        try traceModule.join(id: "test-trace")
        try traceModule.leave()
        let errorDispatchNotTracked = expectation(description: "Error should not be tracked after leaving trace")
        errorDispatchNotTracked.isInverted = true
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorDispatchNotTracked.fulfill()
            }
        }
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Test error" }))
        waitForDefaultTimeout()
    }

    func test_the_module_id_is_correct() {
        XCTAssertNotNil(dataStoreProvider.modulesRepository.getModules()[TraceModule.moduleType])
    }

    func test_forceEndOfVisit_throws_trace_error_when_not_in_trace() {
        XCTAssertThrows(try traceModule.forceEndOfVisit()) { (error: TraceError) in
            guard case .noActiveTrace = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func test_forceEndOfVisit_tracks_dispatch_with_trace_id_twins_and_event_name_when_in_trace() throws {
        let dispatchTracked = expectation(description: "Dispatch should be tracked")
        try traceModule.join(id: "12345")
        _ = tracker.onTrack.subscribeOnce { event in
            XCTAssertEqual(event.name, TealiumConstants.forceEndOfVisitQueryParam)
            XCTAssertEqual(event.payload.get(key: TealiumDataKey.cpTraceId), "12345")
            XCTAssertEqual(event.payload.get(key: TealiumDataKey.tealiumTraceId), "12345")
            XCTAssertEqual(event.payload.get(key: TealiumDataKey.forceEndOfVisitEvent), TealiumConstants.forceEndOfVisitQueryParam)
            dispatchTracked.fulfill()
        }
        try traceModule.forceEndOfVisit()
        waitForDefaultTimeout()
    }

    func test_forceEndOfVisit_completes_without_error_when_dispatch_accepted() throws {
        let completedSuccessfully = expectation(description: "Should complete successfully")
        try traceModule.join(id: "12345")
        try traceModule.forceEndOfVisit { result in
            XCTAssertTrackResultIsAccepted(result)
            completedSuccessfully.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_forceEndOfVisit_completes_with_dropped_when_dispatch_dropped() throws {
        let completesWithDropped = expectation(description: "Exception expected")
        tracker.acceptTrack = false
        try traceModule.join(id: "12345")
        try traceModule.forceEndOfVisit { result in
            XCTAssertTrackResultIsDropped(result)
            completesWithDropped.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_collect_returns_trace_id_twins_after_joining_trace() throws {
        try traceModule.join(id: "12345")
        let context = DispatchContext(source: .application, initialData: [:])
        let collectedData = traceModule.collect(context)
        XCTAssertEqual(collectedData.get(key: TealiumDataKey.cpTraceId), "12345")
        XCTAssertEqual(collectedData.get(key: TealiumDataKey.tealiumTraceId), "12345")
    }

    func test_collect_returns_empty_data_object_after_leaving_trace() throws {
        try traceModule.join(id: "12345")
        try traceModule.leave()
        let context = DispatchContext(source: .application, initialData: [:])
        XCTAssertEqual(traceModule.collect(context).count, 0)
    }

    func test_collect_returns_trace_id_twins_even_when_source_is_trace_module() throws {
        try traceModule.join(id: "12345")
        let context = DispatchContext(source: .module(TraceModule.self), initialData: [:])
        let collectedData = traceModule.collect(context)
        XCTAssertEqual(collectedData.get(key: TealiumDataKey.cpTraceId), "12345")
        XCTAssertEqual(collectedData.get(key: TealiumDataKey.tealiumTraceId), "12345")
    }

    func test_updateConfiguration_updates_trackErrors_setting() {
        let newConfig: DataObject = ["track_errors": true]
        let updatedModule = traceModule.updateConfiguration(newConfig)
        XCTAssertNotNil(updatedModule)
        XCTAssertTrue(traceModule.trackErrors)
    }

    func test_error_subscription_is_created_on_init_when_trace_exists_and_tracking_enabled() throws {
        // Set up existing trace in dataStore
        try dataStoreProvider.getModuleStore(name: TraceModule.moduleType).edit()
            .put(key: TealiumDataKey.tealiumTraceId, value: "existing-trace", expiry: .session)
            .commit()
        let subscribed = expectation(description: "Trace should subscribe")
        traceModule = try createTrace(trackErrors: true,
                                      onErrorEvent: Observables.create(subscriptionHandler: { _ in
            subscribed.fulfill()
            return Disposables.disposed()
        }))
        waitForDefaultTimeout()
    }

    func test_error_subscription_is_not_created_on_init_when_no_trace_exists() throws {
        let subscribed = expectation(description: "Trace should not subscribe")
        subscribed.isInverted = true
        traceModule = try createTrace(trackErrors: true,
                                      onErrorEvent: Observables.create(subscriptionHandler: { _ in
            subscribed.fulfill()
            return Disposables.disposed()
        }))
        waitForDefaultTimeout()
    }

    func test_error_deduplication_tracks_first_error_per_category() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        try traceModule.join(id: "test-trace")
        let errorTracked = expectation(description: "First error should be tracked")
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorTracked.fulfill()
            }
        }
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Error 1" }))
        waitForDefaultTimeout()
        XCTAssertTrue(traceModule.errorCategoryCache.contains("TestCategory"))
    }

    func test_error_deduplication_blocks_duplicate_errors_in_same_category() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        try traceModule.join(id: "test-trace")
        let errorTracked = expectation(description: "Only first error should be tracked")
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorTracked.fulfill()
            }
        }
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Error 1" }))
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Error 2" }))
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Error 3" }))
        waitForDefaultTimeout()
        XCTAssertTrue(traceModule.errorCategoryCache.contains("TestCategory"))
        XCTAssertEqual(traceModule.errorCategoryCache.count, 1)
    }

    func test_error_deduplication_allows_different_categories() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        try traceModule.join(id: "test-trace")
        let errorsTracked = expectation(description: "Errors from different categories should be tracked")
        errorsTracked.expectedFulfillmentCount = 2
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorsTracked.fulfill()
            }
        }
        errorSubject.publish(ErrorEvent(category: "Category1", descriptionProvider: { "Error 1" }))
        errorSubject.publish(ErrorEvent(category: "Category2", descriptionProvider: { "Error 1" }))
        waitForDefaultTimeout()
        XCTAssertTrue(traceModule.errorCategoryCache.contains("Category1"))
        XCTAssertTrue(traceModule.errorCategoryCache.contains("Category2"))
        XCTAssertEqual(traceModule.errorCategoryCache.count, 2)
    }

    func test_errorCategoryCache_starts_empty() {
        XCTAssertTrue(traceModule.errorCategoryCache.isEmpty, "Error category cash should start empty")
    }

    func test_errorCategoryCache_is_cleared_when_leaving_trace() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        try traceModule.join(id: "test-trace")
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Error 1" }))
        XCTAssertTrue(traceModule.errorCategoryCache.contains("TestCategory"))
        try traceModule.leave()
        XCTAssertTrue(traceModule.errorCategoryCache.isEmpty)
    }

    func test_errorCategoryCache_is_cleared_when_joining_new_trace() throws {
        traceModule = try createTrace(trackErrors: true, onErrorEvent: errorSubject.asObservable())
        try traceModule.join(id: "test-trace-1")
        let errorTracked = expectation(description: "Error should be tracked")
        _ = tracker.onTrack.subscribe { event in
            if event.name == "tealium_error" {
                errorTracked.fulfill()
            }
        }
        errorSubject.publish(ErrorEvent(category: "TestCategory", descriptionProvider: { "Error 1" }))
        waitForDefaultTimeout()
        XCTAssertTrue(traceModule.errorCategoryCache.contains("TestCategory"))
        try traceModule.join(id: "test-trace-2")
        XCTAssertTrue(traceModule.errorCategoryCache.isEmpty)
    }
}
