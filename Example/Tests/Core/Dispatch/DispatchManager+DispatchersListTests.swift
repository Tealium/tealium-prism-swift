//
//  DispatchManager+DispatchersListTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchManagerDispatchersListTests: DispatchManagerTestCase {

    func test_event_is_dispatched_to_all_modules() {
        let eventIsDispatchedToModule1 = expectation(description: "Event is dispatched to module1")
        let eventIsDispatchedToModule2 = expectation(description: "Event is dispatched to module2")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatchedToModule1.fulfill()
        }
        module2?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatchedToModule2.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_event_is_not_dispatched_to_old_modules_when_they_get_disabled() {
        let eventIsDispatchedToModule1 = expectation(description: "Event is dispatched to module1")
        let eventIsNotDispatchedToModule2 = expectation(description: "Event is NOT dispatched to module2")
        eventIsNotDispatchedToModule2.isInverted = true
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsDispatchedToModule1.fulfill()
        }
        module2?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventIsNotDispatchedToModule2.fulfill()
        }
        disableModule(module: module2)
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_disabling_a_module_does_not_cancel_inFlight_dispatches() {
        disableModule(module: module2)
        guard let module = module1 else {
            XCTFail("module1 not found")
            return
        }
        module.delay = 0
        let eventsAreDispatched = expectation(description: "Events are dispatched")
        let eventsAreDequeued = expectation(description: "Events are dequeued")
        queueManager.inflightEvents.updates().subscribeOnce { _ in
            module.queue.async {
                self.disableModule(module: module)
            }
            eventsAreDequeued.fulfill()
        }
        _ = module.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        wait(for: [eventsAreDequeued, eventsAreDispatched], timeout: Self.longTimeout, enforceOrder: true)
    }

    func test_closing_the_barrier_does_not_cancel_inFlight_dispatches() throws {
        disableModule(module: module2)
        let module = try XCTUnwrap(module1)
        module.delay = 0
        let eventsAreDequeued = expectation(description: "Events are dequeued")
        let eventsAreDispatched = expectation(description: "Events are dispatched")
        queueManager.inflightEvents.updates().subscribeOnce { _ in
            module.queue.async {
                self.barrier.setState(.closed) // close only once the dispatch is in-flight
            }
            eventsAreDequeued.fulfill()
        }
        _ = module.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        wait(for: [eventsAreDequeued, eventsAreDispatched], timeout: Self.longTimeout, enforceOrder: true)
    }

    func test_disabling_a_dispatcher_deinitializes_the_dispatcher() throws {
        disableModule(module: module2)
        XCTAssertNotNil(module1)
        let eventsAreDispatched = expectation(description: "Events are dispatched")
        _ = module1?.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
        let moduleDeinitialized = expectation(description: "Module is deinitialized")
        module1?.onDeinit.subscribeOnce {
            moduleDeinitialized.fulfill()
        }
        XCTAssertNotNil(module1)
        XCTAssertEqual(moduleManager.modules.value.count, 1)
        disableModule(module: module1)
        XCTAssertEqual(moduleManager.modules.value.count, 0)
        waitForDefaultTimeout()
    }

    // Once a `Dispatcher` is disabled it must never dispatch events that were already sitting in its queue,
    // even if those events are still on disk.
    //
    // Setup note: we disable *every* dispatcher, so the module list ends up empty. This is deliberate.
    // Normally `QueueManager` deletes a dispatcher's queued events the moment it leaves the active processor
    // list, so a disabled dispatcher has nothing left to dequeue no matter what the dispatch chain does.
    // That cleanup is skipped when the module list becomes empty (the processor list ignores an empty list),
    // which keeps module2's events on disk. That is what lets this test assert the guarantee at the
    // dispatch-chain level: module2's loop must be torn down on disable and must not drain those surviving
    // events — rather than the queue simply being emptied out from under it.
    func test_disabled_dispatcher_does_not_dequeue_previously_enqueued_events() throws {
        let module2 = try XCTUnwrap(module2)
        // disable module1 first, so that disabling module2 below empties the module list,
        // therefore avoiding queued events to be auto-purged since empty module list is ignored.
        disableModule(module: module1)
        barrier.setState(.closed) // hold events in the queue, nothing dequeues yet
        _ = dispatchManager // start the loop while the barrier is closed
        let eventsAreNotDispatched = expectation(description: "Disabled dispatcher does not dispatch queued events")
        eventsAreNotDispatched.isInverted = true
        _ = module2.onDispatch.subscribe { _ in
            eventsAreNotDispatched.fulfill()
        }
        queueManager.storeDispatches(createDispatches(amount: 3), enqueueingFor: [module2.id])
        disableModule(module: module2) // tears down module2's dequeue loop
        barrier.setState(.open) // surviving dispatchers may dequeue; module2 must not
        waitForDefaultTimeout()
    }

    // After a module-list change there must be exactly one live dequeue loop for the surviving dispatcher,
    // and none for the removed one. The old chain never disposed a dispatcher's loop, so on a change it
    // leaked the removed dispatcher's loop and stacked a second loop onto each survivor — every one an
    // extra dequeue path that drains the queue faster than intended.
    //
    // We keep the barrier closed so no loop dequeues until we open it, enqueue one event, then open it:
    // each loop that is still alive attempts exactly one dequeue on opening. We wait for that dequeue to
    // actually happen (the `dequeued` expectation); a *second* attempt then means a stale or duplicated loop survived.
    func test_changing_the_dispatchers_list_keeps_a_single_dequeue_loop_per_survivor() throws {
        let module1 = try XCTUnwrap(module1)
        module1.dispatchLimit = 2 // > 1 so a single queued event doesn't spin the resubscribing dequeue loop
        module1.delay = 5000 // keep the dispatched event in-flight so it isn't deleted mid-measurement
        barrier.setState(.closed) // keep every dequeue loop idle until we deliberately open it
        _ = dispatchManager // starts with [module1, module2]
        disableModule(module: module2) // module1 survives; the old chain leaks module2's loop and duplicates module1's

        let dequeued = expectation(description: "a surviving dispatcher dequeues on opening")
        let subsequentDequeueLoop = expectation(description: "only one dequeue loop is alive")
        subsequentDequeueLoop.isInverted = true // a second dequeue attempt means a stale or duplicated loop survived
        var attempts = 0
        _ = queueManager.onDequeueRequest.subscribe { _ in
            attempts += 1
            if attempts == 1 { dequeued.fulfill() } else { subsequentDequeueLoop.fulfill() }
        }
        queueManager.storeDispatches(createDispatches(amount: 1), enqueueingFor: [module1.id])
        barrier.setState(.open) // now the surviving loop(s) run: exactly one dequeue attempt is expected
        wait(for: [dequeued, subsequentDequeueLoop], timeout: Self.defaultTimeout)
    }

    // `startDispatchLoop` is idempotent: `init` already starts the loop, so a redundant call must not stack a
    // second chain on top of the live one — that would give every dispatcher an extra dequeue path, draining
    // the queue past the per-dispatcher inflight limit.
    //
    // Measured like the test above: with the barrier closed nothing dequeues, so after enqueueing one event
    // and opening the barrier each loop that is alive attempts exactly one dequeue.
    func test_starting_the_dispatch_loop_twice_does_not_duplicate_it() throws {
        let module1 = try XCTUnwrap(module1)
        module1.dispatchLimit = 2 // > 1 so a single queued event doesn't spin the resubscribing dequeue loop
        module1.delay = 5000 // keep the dispatched event in-flight so it isn't deleted mid-measurement
        barrier.setState(.closed) // keep every dequeue loop idle until we deliberately open it
        dispatchManager.startDispatchLoop() // the loop is already running since `init`: this must be a no-op

        let dequeued = expectation(description: "module1 dequeues on opening")
        let subsequentDequeueLoop = expectation(description: "only one dequeue loop is alive")
        subsequentDequeueLoop.isInverted = true // a second dequeue attempt means the loop was duplicated
        var attempts = 0
        _ = queueManager.onDequeueRequest.subscribe { processor in
            guard processor == module1.id else { return }
            attempts += 1
            if attempts == 1 { dequeued.fulfill() } else { subsequentDequeueLoop.fulfill() }
        }
        queueManager.storeDispatches(createDispatches(amount: 1), enqueueingFor: [module1.id])
        barrier.setState(.open) // now the surviving loop(s) run: exactly one dequeue attempt is expected
        wait(for: [dequeued, subsequentDequeueLoop], timeout: Self.defaultTimeout)
    }

    // The idempotency guard above must not make the loop unrestartable: `stopDispatchLoop` leaves the manager
    // un-started, so a following `startDispatchLoop` has to build the chain again.
    func test_restarting_the_dispatch_loop_after_stopping_it_resumes_dispatching() {
        _ = dispatchManager // starts the loop
        dispatchManager.stopDispatchLoop()
        dispatchManager.startDispatchLoop()
        let eventsAreDispatched = expectation(description: "Events are dispatched after the loop is restarted")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventsAreDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    // Removing one `Dispatcher` tears down and rebuilds the dequeue loops of the survivors, but must not
    // cancel events already handed to a surviving dispatcher (those live outside the rebuilt `flatMapLatest`).
    func test_disabling_a_dispatcher_does_not_cancel_another_dispatchers_inflight() throws {
        let module1 = try XCTUnwrap(module1)
        module1.delay = 0
        let eventsAreDequeued = expectation(description: "module1 dequeued")
        let eventsAreDispatched = expectation(description: "module1 in-flight completes")
        queueManager.inflightEvents.updates().subscribeOnce { _ in
            module1.queue.async {
                self.disableModule(module: self.module2) // remove a DIFFERENT dispatcher
            }
            eventsAreDequeued.fulfill()
        }
        _ = module1.onDispatch.subscribe { _ in
            eventsAreDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        wait(for: [eventsAreDequeued, eventsAreDispatched], timeout: Self.longTimeout, enforceOrder: true)
    }

    // A `Dispatcher` that was disabled (its chain torn down) must resume dispatching once re-enabled.
    func test_reenabling_a_dispatcher_resumes_dispatching() {
        _ = dispatchManager
        disableModule(module: module1)
        XCTAssertNil(module1)
        enableModule(MockDispatcher1.moduleType)
        XCTAssertNotNil(module1)
        let eventsAreDispatched = expectation(description: "Re-enabled dispatcher dispatches")
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.name, "someEvent")
            eventsAreDispatched.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    // Without `distinct` on `onDispatchers`, every `modules` emission would tear down and rebuild every
    // dispatcher's dequeue loop — including changes that don't affect dispatchers at all (e.g. a
    // non-dispatcher module was added or configured).
    func test_adding_a_non_dispatcher_module_does_not_rebuild_dispatch_chains() throws {
        let moduleId = "module_id"
        let module1 = MockDispatcher1(moduleId: moduleId)
        let modulesSubject = StateSubject<[Module]>([module1])

        // Phase 1: confirm the chain is up. subscribeOnce so any extra startup dequeues
        // (from async barrier-coordinator callbacks) don't pollute phase 2.
        let chainStarted = expectation(description: "dequeue loop fired on barrier open")
        _ = queueManager.onDequeueRequest.subscribeOnce { processor in
            if processor == moduleId {
                chainStarted.fulfill()
            }
        }
        let localDispatchManager = getDispatchManager(modules: modulesSubject.asObservableState())
        defer { localDispatchManager.stopDispatchLoop() }
        wait(for: [chainStarted], timeout: Self.defaultTimeout)

        // Phase 2: adding a non-dispatcher must not trigger another dequeue.
        let spuriousRebuild = expectation(description: "chain was spuriously rebuilt")
        spuriousRebuild.isInverted = true
        _ = queueManager.onDequeueRequest.subscribeOnce { processor in
            if processor == moduleId {
                spuriousRebuild.fulfill()
            }
        }
        modulesSubject.value = [module1, MockCollector()]
        wait(for: [spuriousRebuild], timeout: Self.defaultTimeout)
    }

    // A dispatcher replaced by a new instance with the same `id` must have its chain rebuilt so that
    // dispatches reach the new instance. This is why `distinct` uses instance identity (`===`) rather
    // than `id` equality: `updateConfiguration` mutates a module in place and returns the same instance,
    // so a genuinely new instance — even with the same `id` — must not be collapsed.
    func test_replacing_a_dispatcher_instance_with_same_id_rebuilds_the_chain() throws {
        let originalId = "someId"
        let original = MockDispatcher1(moduleId: originalId)
        let modulesSubject = StateSubject<[Module]>([original])
        let localDispatchManager = getDispatchManager(modules: modulesSubject.asObservableState())
        defer { localDispatchManager.stopDispatchLoop() }

        let replacement = MockDispatcher1(moduleId: originalId) // same id, different instance
        XCTAssert(original !== replacement, "expected a fresh instance, not the original")

        // Single-step swap: count stays 1 → 1. Without identity comparison, `distinct` would see the
        // same id and suppress the emission, leaving `replacement` unreachable.
        modulesSubject.value = [replacement]

        let replacementReceived = expectation(description: "replacement receives the dispatch")
        let originalDidNotReceive = expectation(description: "original must not receive dispatches after being replaced")
        originalDidNotReceive.isInverted = true
        _ = replacement.onDispatch.subscribe { _ in replacementReceived.fulfill() }
        _ = original.onDispatch.subscribe { _ in originalDidNotReceive.fulfill() }

        localDispatchManager.track(Dispatch(name: "someEvent"))
        wait(for: [replacementReceived, originalDidNotReceive], timeout: Self.defaultTimeout)
    }

}
