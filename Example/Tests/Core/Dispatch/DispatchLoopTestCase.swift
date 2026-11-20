//
//  DispatchLoopTestCase.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 20/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// A dispatcher that records what it is sent and completes it asynchronously on main.
/// It can also complete every dispatch of a batch separately, as `CollectModule` does.
final class RecordingDispatcher: MockDispatcher {
    var splitCompletions = false
    /// Called after each completion, once the `DispatchManager` has processed the completed dispatches.
    var onCompleted: (([Dispatch]) -> Void)?
    private(set) var sentIds: [String] = []
    private(set) var batchSizes: [Int] = []
    /// The names of the sent dispatches, in the order they were sent.
    private(set) var sentNames: [String] = []

    override func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> any Disposable {
        sentIds += data.map(\.id)
        sentNames += data.compactMap(\.name)
        batchSizes.append(data.count)
        let parts = splitCompletions ? data.map { [$0] } : [data]
        for part in parts {
            let complete = { [weak self] in
                completion(part)
                self?.onCompleted?(part)
            }
            DispatchQueue.main.async(execute: complete)
        }
        return Subscription { }
    }
}

/**
 * Base class for tests that drive a real `DispatchManager` loop, with a single `RecordingDispatcher`,
 * a real `QueueManager` and the given barriers, all on main. Call `setUpLoop` first, then `start`. The loop is stopped on tear down.
 *
 * No application status is ever emitted: any status starts a flush, which bypasses the `BatchingBarrier`.
 */
class DispatchLoopTestCase: XCTestCase {
    static let dispatcherId = "RecordingDispatcher"
    static let consentConfiguration = ConsentConfiguration(tealiumPurposeId: "tealium",
                                                           refireDispatchersIds: nil,
                                                           purposes: [
                                                            "purpose1": ConsentPurpose(purposeId: "purpose1",
                                                                                       dispatcherIds: [dispatcherId])
                                                           ])
    let dispatcher = RecordingDispatcher(moduleId: dispatcherId)
    private(set) var onDispatchers: StateSubject<[Dispatcher]>!
    private(set) var queueRepository: SQLQueueRepository!
    private(set) var queueManager: MockQueueManager!
    private(set) var consentManager: MockConsentManager?
    private var barrierCoordinator: BarrierCoordinator!
    private let sdkSettings = StateSubject(SDKSettings())
    private var dispatchManager: DispatchManager?
    private var stored = 0
    private let disposer = AutomaticDisposer()

    var queued: Int { queueRepository.queueSize(for: Self.dispatcherId) }
    var inflight: Int { queueManager.inflightEvents.value[Self.dispatcherId]?.count ?? 0 }
    var sent: Int { dispatcher.sentIds.count }

    override func tearDown() {
        dispatchManager?.stopDispatchLoop()
        disposer.dispose()
        super.tearDown()
    }

    /// Builds the components without starting the loop.
    /// - Parameters:
    ///   - consent: Adds a `MockConsentManager`, which has no configuration until one is published.
    ///   - barriers: The barriers, all scoped to every dispatcher. Built after the `queueManager`, so they can use it.
    func setUpLoop(dispatchLimit: Int,
                   consent: Bool = false,
                   barriers: () -> [Barrier] = { [] }) {
        dispatcher.dispatchLimit = dispatchLimit
        let onDispatchers = StateSubject<[Dispatcher]>([dispatcher])
        let queueRepository = SQLQueueRepository(dbProvider: MockDatabaseProvider(), maxQueueSize: 1000, expiration: 1.days)
        let queueManager = MockQueueManager(processors: onDispatchers.asObservable().map { $0.map(\.id) },
                                            queueRepository: queueRepository,
                                            coreSettings: StateSubject(CoreSettings(maxQueueSize: 1000)).asObservableState(),
                                            logger: nil)
        self.onDispatchers = onDispatchers
        self.queueRepository = queueRepository
        self.queueManager = queueManager
        let scopedBarriers: [ScopedBarrier] = barriers().map { ($0, BarrierScope.all) }
        consentManager = consent ? MockConsentManager() : nil
        barrierCoordinator = BarrierCoordinator(onScopedBarriers: Observables.just(scopedBarriers),
                                                onApplicationStatus: Observables.empty(),
                                                queueMetrics: queueManager,
                                                queue: .main)
    }

    /// A `BatchingBarrier` for the loop's dispatcher: `nil` uses the default batch size, the `dispatchLimit`.
    func batchingBarrier(batchSize: Int?) -> Barrier {
        let configuration: DataObject = batchSize.map { ["batch_size": $0] } ?? [:]
        return BatchingBarrier(queueMetrics: queueManager, onDispatchers: onDispatchers.asObservable(), configuration: configuration)
    }

    func stop() {
        dispatchManager?.stopDispatchLoop()
    }

    /// Starts the loop again on the existing `DispatchManager`, which already started one in its `init`.
    func restart() {
        dispatchManager?.startDispatchLoop()
    }

    func start() {
        dispatchManager = DispatchManager(loadRuleEngine: LoadRuleEngine(sdkSettings: sdkSettings.asObservableState(), logger: nil),
                                          onDispatchers: onDispatchers.asObservable(),
                                          consentManager: consentManager,
                                          queueManager: queueManager,
                                          barrierCoordinator: barrierCoordinator,
                                          transformerCoordinator: TransformerCoordinator(onTransformers: Observables.just([]),
                                                                                         transformations: StateSubject([]).asObservableState(),
                                                                                         queue: .main,
                                                                                         logger: nil),
                                          mappingsEngine: MappingsEngine(mappings: .constant([:])),
                                          queue: .main,
                                          logger: nil)
    }

    /// An expectation fulfilled once for every dispatch completed and processed by the `DispatchManager`.
    @discardableResult
    func expectCompletedDispatches(_ count: Int) -> XCTestExpectation {
        let completed = expectation(description: "\(count) dispatches are completed")
        completed.expectedFulfillmentCount = count
        dispatcher.onCompleted = { dispatches in
            dispatches.forEach { _ in completed.fulfill() }
        }
        return completed
    }

    /// An expectation fulfilled once the `total` dispatches are all either completed, or left in the queue below `batchSize`.
    @discardableResult
    func expectSettled(total: Int, below batchSize: Int) -> XCTestExpectation {
        let settled = expectation(description: "\(total) dispatches are completed or left below the batch size")
        settled.assertForOverFulfill = false
        dispatcher.onCompleted = { [weak self] _ in
            guard let self, inflight == 0, queued < batchSize, sent + queued == total else { return }
            settled.fulfill()
        }
        return settled
    }

    /// Tracks `count` events one by one, through the `DispatchManager`. Only enqueues without a consent manager.
    func track(_ count: Int) {
        for _ in 0..<count {
            stored += 1
            dispatchManager?.track(Dispatch(name: "event\(stored)"))
        }
    }

    /// Stores `count` consented events in the queue at once.
    func store(_ count: Int) throws {
        let dispatches = (0..<count).map { _ -> Dispatch in
            stored += 1
            return Dispatch(name: "event\(stored)", data: [TealiumDataKey.allConsentedPurposes: ["purpose1"]])
        }
        try queueManager.storeDispatches(dispatches, enqueueingFor: [Self.dispatcherId])
    }

    func publishConsent(_ configuration: ConsentConfiguration?) {
        consentManager?._onConfigurationSelected.onNext(configuration)
    }

    /// Runs `action` once, synchronously from within the first dequeue, right after it marks the dispatches inflight.
    func onFirstDequeue(_ action: @escaping () -> Void) {
        queueManager.onInflightDispatchesCount(for: Self.dispatcherId)
            .filter { $0 > 0 }
            .subscribeOnce { _ in action() }
            .addTo(disposer)
    }

    /// Asserts that `sent` dispatches were sent once each, that `queued` are still in the queue, and that none is inflight.
    func assertSettled(sent: Int, queued: Int = 0, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(self.sent, sent, "sent", file: file, line: line)
        XCTAssertEqual(Set(dispatcher.sentIds).count, sent, "sent only once", file: file, line: line)
        XCTAssertEqual(self.queued, queued, "queued", file: file, line: line)
        XCTAssertEqual(inflight, 0, "inflight", file: file, line: line)
    }

    /// Asserts that the first `count` events tracked or stored were sent in order, with none skipped or repeated.
    func assertSentInOrder(_ count: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(dispatcher.sentNames, (1...count).map { "event\($0)" }, "sent in queue order", file: file, line: line)
    }
}

/// Opens while the dispatches pending for a dispatcher are at least `threshold`, reacting synchronously to `QueueMetrics`.
final class PendingAtLeastBarrier: Barrier {
    private let queueMetrics: QueueMetrics
    private let threshold: Int

    init(queueMetrics: QueueMetrics, threshold: Int) {
        self.queueMetrics = queueMetrics
        self.threshold = threshold
    }

    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        queueMetrics.onQueueSizePendingDispatch(for: dispatcherId)
            .map { [threshold] in $0 >= threshold ? .open : .closed }
            .distinct()
    }
}

/// Opens while the dispatches inflight for a dispatcher are at most `maxInflight`, reacting synchronously to the queue.
final class InflightAtMostBarrier: Barrier {
    private let queueManager: QueueManagerProtocol
    private let maxInflight: Int

    init(queueManager: QueueManagerProtocol, maxInflight: Int) {
        self.queueManager = queueManager
        self.maxInflight = maxInflight
    }

    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        queueManager.onInflightDispatchesCount(for: dispatcherId)
            .map { [maxInflight] in $0 <= maxInflight ? .open : .closed }
            .distinct()
    }
}
