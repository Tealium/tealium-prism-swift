//
//  DispatchManager+LoopStrandingTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 20/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// The real dispatch loop must never strand a dequeued batch inflight.
final class DispatchManagerLoopStrandingTests: DispatchLoopTestCase {

    // MARK: - Barriers

    /**
     * With a batch size of 1, a dequeue that empties the pending queue closes the `BatchingBarrier` from
     * within the dequeue itself. That `.closed` must not tear down the dequeue loop before the dequeued batch
     * is emitted, or those dispatches stay inflight forever.
     */
    func test_batching_barrier_closing_during_a_dequeue_does_not_strand_the_dequeued_dispatches() {
        setUpLoop(dispatchLimit: 10) { [batchingBarrier(batchSize: 1)] }
        expectCompletedDispatches(100)
        start()
        track(100)
        waitForLongTimeout()
        assertSettled(sent: 100)
    }

    /// Per-event completions lower the inflight count one by one, and only a remainder below the batch size waits.
    ///
    /// A dequeue can happen while only some of a batch is completed, so batches may be smaller than 10 and the remainder is not necessarily 105 % 10.
    func test_batching_barrier_with_split_completions_leaves_only_a_remainder_below_the_batch_size() {
        setUpLoop(dispatchLimit: 10) { [batchingBarrier(batchSize: nil)] }
        dispatcher.splitCompletions = true
        expectSettled(total: 105, below: 10)
        start()
        track(105)
        waitForLongTimeout()
        let remaining = queued
        XCTAssertLessThan(remaining, 10)
        assertSettled(sent: 105 - remaining, queued: remaining)
    }

    /// A custom barrier reacting synchronously to the pending count closes from within the dequeues.
    func test_barrier_closing_on_the_pending_count_during_a_dequeue_does_not_strand_the_dequeued_dispatches() {
        setUpLoop(dispatchLimit: 10) { [PendingAtLeastBarrier(queueMetrics: queueManager, threshold: 5)] }
        expectSettled(total: 60, below: 5)
        start()
        track(60)
        waitForLongTimeout()
        let remaining = queued
        XCTAssertLessThan(remaining, 5)
        assertSettled(sent: 60 - remaining, queued: remaining)
    }

    /// A custom barrier reacting synchronously to the inflight count closes from within every dequeue.
    func test_barrier_closing_on_the_inflight_count_during_a_dequeue_does_not_strand_the_dequeued_dispatches() {
        setUpLoop(dispatchLimit: 10) { [InflightAtMostBarrier(queueManager: queueManager, maxInflight: 5)] }
        expectCompletedDispatches(20)
        start()
        track(20)
        waitForLongTimeout()
        assertSettled(sent: 20)
    }

    // MARK: - Consent

    /// The first consent configuration starts a dequeue that closes the `BatchingBarrier` from within itself.
    func test_batching_barrier_closing_during_the_first_consented_dequeue_does_not_strand_the_dequeued_dispatches() throws {
        setUpLoop(dispatchLimit: 10, consent: true) { [batchingBarrier(batchSize: 10)] }
        start()
        publishConsent(nil)
        try store(15)
        XCTAssertEqual(inflight, 0, "Nothing is dequeued without a consent configuration")
        expectCompletedDispatches(10)
        publishConsent(Self.consentConfiguration)
        waitForLongTimeout()
        assertSettled(sent: 10, queued: 5)
    }

    /// Removing the consent configuration during a dequeue doesn't strand the dequeued batch,
    /// and the rest is sent once a configuration is published again.
    func test_consent_configuration_removed_during_a_dequeue_does_not_strand_the_dequeued_dispatches() throws {
        setUpLoop(dispatchLimit: 10, consent: true)
        start()
        publishConsent(Self.consentConfiguration)
        onFirstDequeue {
            self.publishConsent(nil)
        }
        expectCompletedDispatches(10)
        try store(25)
        waitForLongTimeout()
        assertSettled(sent: 10, queued: 15)
        expectCompletedDispatches(15)
        publishConsent(Self.consentConfiguration)
        waitForLongTimeout()
        assertSettled(sent: 25)
    }

    // MARK: - Dispatchers list

    /// The batch is still processed by the dispatcher captured when it was requested.
    func test_dispatchers_reemitted_during_a_dequeue_do_not_strand_the_dequeued_dispatches() throws {
        setUpLoop(dispatchLimit: 10)
        start()
        onFirstDequeue {
            self.onDispatchers.value = [self.dispatcher]
        }
        expectCompletedDispatches(25)
        try store(25)
        waitForLongTimeout()
        assertSettled(sent: 25)
    }

    // MARK: - Stop

    /// A `stopDispatchLoop()` issued from within the first dequeue, while the loop is still being set up, leaves it stopped.
    func test_stopDispatchLoop_from_within_the_first_dequeue_leaves_the_loop_stopped() throws {
        setUpLoop(dispatchLimit: 10)
        start()
        stop()
        try store(25)
        onFirstDequeue {
            self.stop()
        }
        restart()
        drainMainQueue()
        try store(5)
        drainMainQueue()
        XCTAssertLessThanOrEqual(sent, 10, "Nothing is dequeued after the first batch")
        XCTAssertEqual(queued, 30, "The stopped loop processes no completion, so nothing is deleted")
    }

    // MARK: - Order

    /// A backlog is drained through the async follow-up dequeues without reordering the batches.
    func test_a_backlog_is_dispatched_in_queue_order() throws {
        setUpLoop(dispatchLimit: 10)
        expectCompletedDispatches(105)
        try store(105)
        start()
        waitForLongTimeout()
        assertSettled(sent: 105)
        assertSentInOrder(105)
    }

    /// A burst of tracked events behind a `BatchingBarrier` is sent in order, and only a remainder below the batch size waits.
    func test_a_burst_with_a_batching_barrier_is_dispatched_in_queue_order() {
        setUpLoop(dispatchLimit: 10) { [batchingBarrier(batchSize: 10)] }
        dispatcher.splitCompletions = true
        expectSettled(total: 105, below: 10)
        start()
        track(105)
        waitForLongTimeout()
        let remaining = queued
        XCTAssertLessThan(remaining, 10)
        assertSettled(sent: 105 - remaining, queued: remaining)
        XCTAssertEqual(dispatcher.sentNames, (1...(105 - remaining)).map { "event\($0)" }, "sent in queue order")
    }

    /// The dispatches released when the in-flight threshold is hit and then lowered keep the queue order.
    func test_dispatches_released_by_the_inflight_threshold_are_dispatched_in_queue_order() throws {
        setUpLoop(dispatchLimit: 1)
        expectCompletedDispatches(120)
        try store(120)
        start()
        waitForLongTimeout()
        assertSettled(sent: 120)
        assertSentInOrder(120)
    }

    /// The backlog stored before the first consent configuration is dispatched in order once it is published.
    func test_a_consent_configuration_published_over_a_backlog_dispatches_in_queue_order() throws {
        setUpLoop(dispatchLimit: 10, consent: true)
        start()
        publishConsent(nil)
        try store(25)
        expectCompletedDispatches(25)
        publishConsent(Self.consentConfiguration)
        waitForLongTimeout()
        assertSettled(sent: 25)
        assertSentInOrder(25)
    }

    /// Re-emitting the dispatchers between two dequeues doesn't reorder the rest of the queue.
    func test_dispatchers_reemitted_between_dequeues_keep_queue_order() throws {
        setUpLoop(dispatchLimit: 10)
        expectCompletedDispatches(25)
        try store(25)
        start()
        XCTAssertEqual(inflight, 10, "Only the first batch is dequeued before the main queue runs")
        onDispatchers.value = [dispatcher]
        waitForLongTimeout()
        assertSettled(sent: 25)
        assertSentInOrder(25)
    }

    // MARK: - In-flight and dispatchLimit

    func test_the_whole_queue_is_sent_when_dispatchLimit_is_higher_than_the_maximum_inflight() throws {
        setUpLoop(dispatchLimit: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 10)
        expectCompletedDispatches(120)
        try store(120)
        start()
        waitForLongTimeout()
        assertSettled(sent: 120)
        XCTAssertEqual(dispatcher.batchSizes, [50, 50, 20])
    }

    /// A `dispatchLimit` of 0 dequeues one dispatch at a time, without requesting dequeues forever.
    func test_dispatchLimit_of_zero_dispatches_one_event_at_a_time_without_spinning() throws {
        try assertDispatchesOneEventAtATimeWithoutSpinning(dispatchLimit: 0)
    }

    /// A negative `dispatchLimit` is handled as 1.
    func test_negative_dispatchLimit_dispatches_one_event_at_a_time_without_spinning() throws {
        try assertDispatchesOneEventAtATimeWithoutSpinning(dispatchLimit: -1)
    }

    func test_the_whole_queue_is_sent_when_dispatchLimit_is_higher_than_the_maximum_inflight_and_enqueued_after_start() throws {
        setUpLoop(dispatchLimit: DispatchManager.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER + 10)
        expectCompletedDispatches(120)
        start()
        try store(120)
        waitForLongTimeout()
        assertSettled(sent: 120)
        XCTAssertEqual(dispatcher.batchSizes, [50, 50, 20])
    }

    /// Draining a long backlog must not nest each dequeue inside the previous one.
    func test_draining_a_long_backlog_does_not_grow_the_stack() throws {
        setUpLoop(dispatchLimit: 1)
        let total = 1000
        expectCompletedDispatches(total)
        let disposer = AutomaticDisposer()
        var maxDepth = 0
        queueManager.onDequeueRequest.subscribe { _ in
            maxDepth = max(maxDepth, Thread.callStackReturnAddresses.count)
        }.addTo(disposer)
        try store(total)
        start()
        waitForLongTimeout()
        assertSettled(sent: total)
        XCTAssertLessThan(maxDepth, 500)
    }

    private func assertDispatchesOneEventAtATimeWithoutSpinning(dispatchLimit: Int, file: StaticString = #filePath, line: UInt = #line) throws {
        setUpLoop(dispatchLimit: dispatchLimit)
        let disposer = AutomaticDisposer()
        var dequeueRequests = 0
        queueManager.onDequeueRequest.subscribe { _ in
            dequeueRequests += 1
        }.addTo(disposer)
        expectCompletedDispatches(3)
        try store(3)
        start()
        waitForLongTimeout()
        drainMainQueue()
        assertSettled(sent: 3, file: file, line: line)
        XCTAssertEqual(dispatcher.batchSizes, [1, 1, 1], file: file, line: line)
        XCTAssertLessThanOrEqual(dequeueRequests, 3 + 1, file: file, line: line)
    }
}
