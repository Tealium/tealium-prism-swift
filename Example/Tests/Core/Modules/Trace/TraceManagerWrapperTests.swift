//
//  TraceManagerWrapperTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TraceManagerWrapperTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = TraceManagerWrapper(moduleProxy: ModuleProxy(onModulesManager: onManager.asObservable()))
    @StateSubject(CoreSettings())
    var coreSettings
    func context() -> TealiumContext {
        TealiumContext(modulesManager: manager,
                       config: config,
                       coreSettings: coreSettings,
                       tracker: tracker,
                       barrierRegistry: BarrierManager(sdkBarrierSettings: StateSubject([:]).toStatefulObservable()),
                       transformerRegistry: TransformerCoordinator(transformers: StateSubject([]).toStatefulObservable(),
                                                                   transformations: StateSubject([]).toStatefulObservable(),
                                                                   moduleMappings: StateSubject([:]).toStatefulObservable(),
                                                                   queue: queue),
                       databaseProvider: dbProvider,
                       moduleStoreProvider: ModuleStoreProvider(databaseProvider: dbProvider,
                                                                modulesRepository: SQLModulesRepository(dbProvider: dbProvider)),
                       logger: nil,
                       networkHelper: MockNetworkHelper(),
                       activityListener: ApplicationStatusListener.shared,
                       queue: queue,
                       visitorId: mockVisitorId)
    }

    override func setUp() {
        config.modules = [TealiumModules.trace()]
        manager.updateSettings(context: context(), settings: SDKSettings([:]))
    }

    func test_join_calls_module_method_which_adds_trace_id() {
        let joinCalled = expectation(description: "Join is called")
        manager.getModule(TraceManagerModule.self)?.dataStore.onDataUpdated.subscribeOnce({ data in
            if data.get(key: TealiumDataKey.traceId) == "12345" {
                joinCalled.fulfill()
            }
        })
        wrapper.join(id: "12345")
        waitOnQueue(queue: queue)
    }

    func test_leave_calls_module_method_which_removes_trace_id() {
        let leaveCalled = expectation(description: "Leave is called")
        manager.getModule(TraceManagerModule.self)?.dataStore.onDataRemoved.subscribeOnce({ data in
            if data.contains(TealiumDataKey.traceId) {
                leaveCalled.fulfill()
            }
        })
        wrapper.join(id: "12345")
        wrapper.leave()
        waitOnQueue(queue: queue)
    }

    func test_killVisitorSession_calls_module_method_which_tracks_dispatch() {
        let killVisitorSessionCalled = expectation(description: "KillVisitorSession is called")
        tracker.onTrack.subscribeOnce({ dispatch in
            if dispatch.name == TealiumKey.killVisitorSession {
                killVisitorSessionCalled.fulfill()
            }
        })
        wrapper.join(id: "12345")
        wrapper.killVisitorSession()
        waitOnQueue(queue: queue)
    }

    // MARK: the following 3 tests are needed due to custom completion logic of this method inside wrapper
    // currently, this is the only case when completion called outside track (since track doesn't throw)
    func test_killVisitorSession_completes_with_moduleNotEnabled_error_when_module_disabled() {
        let errorCaught = expectation(description: "Error caught")
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [TraceManagerModule.id: ModuleSettingsBuilder().setEnabled(false).build()]))
        _ = wrapper.killVisitorSession().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled = error as? TealiumError else {
                    XCTFail("Unexpected error: \(String(describing: error))")
                    return
                }
                errorCaught.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_killVisitorSession_completion_called_only_once_with_nil_on_successful_track() {
        let completionCalled = expectation(description: "Completion is called")
        wrapper.join(id: "12345")
        _ = wrapper.killVisitorSession().subscribe { result in
            XCTAssertResultIsSuccess(result)
            completionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_killVisitorSession_completion_called_only_once_with_success_on_dropped_dispatch() {
        let completionCalled = expectation(description: "Completion is called")
        tracker.acceptTrack = false
        wrapper.join(id: "12345")
        _ = wrapper.killVisitorSession().subscribe { result in
            XCTAssertResultIsSuccess(result) { trackResult in
                XCTAssertTrackResultIsDropped(trackResult)
            }
            completionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }
    // MARK: end of custom completion tests
}
