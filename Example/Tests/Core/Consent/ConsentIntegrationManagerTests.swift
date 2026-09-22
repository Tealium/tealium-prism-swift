//
//  ConsentIntegrationManagerTests.swift
//  tealium-prism_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class ConsentIntegrationManagerBaseTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let allDispatchers = [MockDispatcher1(moduleId: MockDispatcher1.moduleType), MockDispatcher2(moduleId: MockDispatcher2.moduleType)]
    var allDispatchersIds: [String] {
        allDispatchers.map { $0.id }
    }
    lazy var moduleManager = ModuleManager(initialModules: allDispatchers)
    @StateSubject(CoreSettings())
    var coreSettings
    lazy var queueManager = buildQueueManager()
    func buildQueueManager() -> MockQueueManager {
        let processors = TealiumImpl.queueProcessors(from: moduleManager.observeModules { $0 as? Dispatcher },
                                                     addingConsent: true)
        let repository = SQLQueueRepository(dbProvider: databaseProvider,
                                            maxQueueSize: 10,
                                            expiration: 1.days)
        return MockQueueManager(processors: processors,
                                queueRepository: repository,
                                coreSettings: coreSettings,
                                logger: nil)
    }
    @StateSubject([])
    var transformations: ObservableState<[TransformationSettings]>
    lazy var transformerCoordinator = TransformerCoordinator(onTransformers: Observables.just([]),
                                                             transformations: transformations,
                                                             queue: .main,
                                                             logger: nil)

    static func buildConsentSettings(refireDispatchers: [String] = []) -> ConsentSettings {
        let configuration = ConsentConfiguration(tealiumPurposeId: "tealium",
                                                 refireDispatchersIds: refireDispatchers,
                                                 purposes: [:])
        return ConsentSettings(configurations: ["MockCMP": configuration])
    }
    @StateSubject(buildConsentSettings())
    var consentSettings: ObservableState<ConsentSettings?>

    let adapter = MockCMPAdapter(consentDecision: nil)

    lazy var consentManager = buildConsentManager(cmpAdapter: adapter)

    func buildConsentManager(cmpAdapter: CMPAdapter,
                             modules: ObservableState<[Module]>? = nil) -> ConsentIntegrationManager {
        let cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                   cmpAdapter: cmpAdapter,
                                                   queue: .main)
        return ConsentIntegrationManager(queueManager: queueManager,
                                         modules: modules ?? moduleManager.modules,
                                         consentSettings: consentSettings,
                                         cmpSelector: cmpSelector,
                                         logger: nil)
    }

    func updateConsentSettings(consentSettings: ConsentSettings) {
        _consentSettings.value = consentSettings
    }
}

final class ConsentIntegrationManagerTests: ConsentIntegrationManagerBaseTests {
    let completionCalledDescription = "Completion was called"

    func applyDecision(decisionType: ConsentDecision.DecisionType, purposes: Set<String>) {
        adapter.applyDecision(ConsentDecision(decisionType: decisionType, purposes: purposes))
    }

    func test_applyConsent_returns_dropped_result_and_original_dispatch_when_explicitly_not_tealium_consented() {
        applyDecision(decisionType: .explicit, purposes: [])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        XCTAssertTrackResultIsDropped(result) { dispatch in
            XCTAssertEqual(dispatch.payload.count, 4)
        }
    }

    func test_applyConsent_returns_accepted_result_and_original_dispatch_when_implicitly_not_tealium_consented() {
        applyDecision(decisionType: .implicit, purposes: [])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        XCTAssertTrackResultIsAccepted(result) { dispatch in
            XCTAssertEqual(dispatch.payload.count, 4)
        }
    }

    func test_applyConsent_returns_accepted_result_and_consented_dispatch_when_tealium_consented() {
        applyDecision(decisionType: .explicit, purposes: ["tealium"])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        XCTAssertTrackResultIsAccepted(result) { dispatch in
            XCTAssertNotEqual(dispatch.payload.count, 3)
            XCTAssertNotNil(dispatch.payload.getDataItem(key: TealiumDataKey.consentType))
        }
    }

    func test_applyConsent_returns_dropped_result_and_original_dispatch_when_unprocessed_purposes_empty() {
        applyDecision(decisionType: .explicit, purposes: ["tealium"])
        var dispatch = Dispatch(name: "event1")
        dispatch.enrich(data: [TealiumDataKey.allConsentedPurposes: ["tealium"]]) // this is gonna be the 3rd property of payload...
        let result = consentManager.applyConsent(to: dispatch)
        XCTAssertTrackResultIsDropped(result) { dispatch in
            XCTAssertEqual(dispatch.payload.count, 5) // ...that's why 5 is here
        }
    }

    func test_applyConsent_returns_accepted_before_consentDecision_is_given() {
        let result = consentManager.applyConsent(to: Dispatch(name: "event"))
        XCTAssertTrackResultIsAccepted(result)
    }

    func test_applyConsent_enqueues_for_consent_if_decision_allows_refire() {
        let dispatchQueued = expectation(description: "Dispatch queued")
        updateConsentSettings(consentSettings: Self.buildConsentSettings(refireDispatchers: [MockDispatcher1.moduleType]))
        applyDecision(decisionType: .implicit, purposes: ["tealium"])

        _ = queueManager.onStoreRequest.subscribe { _, processors in
            XCTAssertTrue(processors.contains(ConsentIntegrationManager.id))
            dispatchQueued.fulfill()
        }

        let result = consentManager.applyConsent(to: Dispatch(name: "event"))
        XCTAssertTrackResultIsAccepted(result)
        waitForDefaultTimeout()
    }

    func test_enqueueDispatches_are_normally_stored_for_all_dispatchers() {
        let dispatchesStored = expectation(description: "Dispatches are stored")
        let dispatches = [
            Dispatch(name: "event1"),
            Dispatch(name: "event2"),
            Dispatch(name: "event3")
        ]
        let refireDispatchers = [MockDispatcher1.moduleType, MockDispatcher2.moduleType]
        _ = queueManager.onStoreRequest
            .subscribe { storedDispatches, storingDispatchers in
                XCTAssertEqual(storedDispatches.map { $0.id },
                               dispatches.map { $0.id })
                XCTAssertEqual(storingDispatchers, self.allDispatchersIds)
                dispatchesStored.fulfill()
            }
        consentManager.enqueueDispatches(dispatches,
                                         refireDispatchers: refireDispatchers)
        waitForDefaultTimeout()
    }

    func test_enqueueDispatches_are_stored_for_refire_when_containing_already_processed_purposes() {
        let dispatchesStored = expectation(description: "Dispatches are stored")
        let dispatches = [
            Dispatch(name: "event1",
                     data: [TealiumDataKey.processedPurposes: ["purpose"]]),
            Dispatch(name: "event2",
                     data: [TealiumDataKey.processedPurposes: ["purpose"]]),
            Dispatch(name: "event3",
                     data: [TealiumDataKey.processedPurposes: ["purpose"]])
        ]
        let refireDispatchers = [MockDispatcher1.moduleType, MockDispatcher2.moduleType]
        _ = queueManager.onStoreRequest
            .subscribe { storedDispatches, storingDispatchers in
                XCTAssertEqual(storedDispatches.map { $0.id },
                               dispatches.map { $0.id + "-refire" })
                XCTAssertEqual(storingDispatchers, refireDispatchers)
                dispatchesStored.fulfill()
            }
        consentManager.enqueueDispatches(dispatches,
                                         refireDispatchers: refireDispatchers)
        waitForDefaultTimeout()
    }

    /**
     * `refireDispatchersIds` comes from the consent settings, so it can name a dispatcher that is not
     * enabled - a typo, or a module that isn't installed. Enqueueing for it stores the dispatches for
     * a processor that no dequeue loop reads, and that the queue deletes at the next processors change
     * (see `QueueManagerTests.test_modules_changes_removes_dispatches_queued_to_old_processors`), so
     * they are never sent and nothing is reported. They also take up part of the shared `maxQueueSize`.
     */
    func test_enqueueDispatches_does_not_store_for_refire_dispatchers_that_are_not_enabled() {
        XCTExpectFailure("""
                         Known gap: the refire ids are used as processors without being checked \
                         against the enabled dispatchers. Remove this expectation once the unknown \
                         ids are dropped, and logged, instead of being enqueued for.
                         """)
        // Already processed purposes, so these dispatches take the refire path.
        let dispatches = [Dispatch(name: "event",
                                   data: [TealiumDataKey.processedPurposes: ["purpose"]])]
        var storedFor = [[String]]()
        _ = queueManager.onStoreRequest.subscribe { _, processors in
            storedFor.append(processors)
        }
        consentManager.enqueueDispatches(dispatches,
                                         refireDispatchers: [MockDispatcher1.moduleType, "notADispatcher"])
        XCTAssertEqual(storedFor, [[MockDispatcher1.moduleType]],
                       "The enabled refire dispatcher must be kept, and the unknown id dropped")
    }

    func test_enqueueDispatches_are_stored_in_two_batches_when_contain_both_normal_and_refire_dispatches() {
        let dispatchesStored = expectation(description: "Dispatches are stored")
        dispatchesStored.expectedFulfillmentCount = 2
        let dispatches = [
            Dispatch(name: "event1",
                     data: [TealiumDataKey.processedPurposes: ["purpose"]]),
            Dispatch(name: "event2"),
            Dispatch(name: "event3",
                     data: [TealiumDataKey.processedPurposes: ["purpose"]]),
            Dispatch(name: "event4"),
        ]
        let refireDispatchers = [MockDispatcher1.moduleType, MockDispatcher2.moduleType]
        var firstEventHappened = false
        _ = queueManager.onStoreRequest
            .subscribe { storedDispatches, storingDispatchers in
                if !firstEventHappened {
                    firstEventHappened = true
                    XCTAssertEqual(storedDispatches.map { $0.id },
                                   [dispatches[0], dispatches[2]].map { $0.id + "-refire" })
                    XCTAssertEqual(storingDispatchers, refireDispatchers)
                } else {
                    XCTAssertEqual(storedDispatches.map { $0.id },
                                   [dispatches[1], dispatches[3]].map { $0.id })
                    XCTAssertEqual(storingDispatchers, self.allDispatchersIds)
                }
                dispatchesStored.fulfill()
            }
        consentManager.enqueueDispatches(dispatches,
                                         refireDispatchers: refireDispatchers)
        waitForDefaultTimeout()
    }

    func test_handleConsentInspectorChange_deletes_all_dispatches_in_consent_queue() {
        let deleteAllRequest = expectation(description: "All consent dispatch are deleted")
        let config = ConsentConfiguration(tealiumPurposeId: "",
                                          refireDispatchersIds: nil,
                                          purposes: [:])
        let decision = ConsentDecision(decisionType: .implicit,
                                       purposes: [])
        let inspector = ConsentInspector(configuration: config,
                                         decision: decision,
                                         allPurposes: nil)
        queueManager.onDeleteAllRequest.subscribeOnce { processor in
            XCTAssertEqual(processor, ConsentIntegrationManager.id)
            deleteAllRequest.fulfill()
        }
        consentManager.handleConsentInspectorChange(inspector)
        waitForDefaultTimeout()
    }

    func test_handleConsentInspectorChange_enqueue_normal_dispatches_when_purposes_are_consented() {
        let storeRequest = expectation(description: "All consent dispatch are stored")
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: ["refireDispatcher"],
                                          purposes: [
                                            "purpose": ConsentPurpose(purposeId: "purpose",
                                                                      dispatcherIds: ["dispatcher"])
                                          ])
        let decision = ConsentDecision(decisionType: .implicit,
                                       purposes: ["purpose"])
        let inspector = ConsentInspector(configuration: config,
                                         decision: decision,
                                         allPurposes: nil)
        let dispatches = [Dispatch(name: "event")]
        queueManager.storeDispatches(dispatches,
                                     enqueueingFor: [ConsentIntegrationManager.id])
        queueManager.onStoreRequest.subscribeOnce { storedDispatches, allDispatchers in
            XCTAssertEqual(storedDispatches.map { $0.id }, dispatches.map { $0.id })
            XCTAssertEqual(allDispatchers, self.allDispatchersIds,
                           "Store needs to happen for all queueManager's dispatchers for non refire dispatches.")
            storeRequest.fulfill()
        }
        consentManager.handleConsentInspectorChange(inspector)
        waitForDefaultTimeout()
    }

    func test_handleConsentInspectorChange_enqueue_refire_dispatches_when_purposes_are_consented() {
        let storeRequest = expectation(description: "All consent dispatch are stored")
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: [MockDispatcher1.moduleType],
                                          purposes: [
                                            "purpose": ConsentPurpose(purposeId: "purpose",
                                                                      dispatcherIds: ["dispatcher"])
                                          ])
        let decision = ConsentDecision(decisionType: .implicit,
                                       purposes: ["purpose"])
        let inspector = ConsentInspector(configuration: config,
                                         decision: decision,
                                         allPurposes: nil)
        let dispatches = [Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["some_purpose"]
        ])]
        queueManager.storeDispatches(dispatches,
                                     enqueueingFor: [ConsentIntegrationManager.id])
        queueManager.onStoreRequest.subscribeOnce { storedDispatches, refireDispatchers in
            XCTAssertEqual(storedDispatches.map { $0.id },
                           dispatches.map { $0.id + "-refire" })
            XCTAssertEqual(refireDispatchers, [MockDispatcher1.moduleType])
            storeRequest.fulfill()
        }
        consentManager.handleConsentInspectorChange(inspector)
        waitForDefaultTimeout()
    }

    func test_handleConsentInspectorChange_doesnt_enqueue_dispatches_when_purposes_are_not_consented() {
        let storeRequest = expectation(description: "No consent dispatch are stored")
        storeRequest.isInverted = true
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: nil,
                                          purposes: [
                                            "purpose": ConsentPurpose(purposeId: "purpose",
                                                                      dispatcherIds: ["dispatcher"])
                                          ])
        let decision = ConsentDecision(decisionType: .implicit,
                                       purposes: [])
        let inspector = ConsentInspector(configuration: config,
                                         decision: decision,
                                         allPurposes: nil)
        let dispatches = [Dispatch(name: "event")]
        queueManager.storeDispatches(dispatches,
                                     enqueueingFor: [ConsentIntegrationManager.id])
        queueManager.onStoreRequest.subscribeOnce { _, _ in
            storeRequest.fulfill()
        }
        consentManager.handleConsentInspectorChange(inspector)
        waitForDefaultTimeout()
    }

    func test_handleConsentInspectorChange_doesnt_enqueue_dispatches_when_tealium_explicitly_blocked() {
        let storeRequest = expectation(description: "No consent dispatch are stored")
        storeRequest.isInverted = true
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: nil,
                                          purposes: [
                                            "purpose": ConsentPurpose(purposeId: "purpose",
                                                                      dispatcherIds: ["dispatcher"])
                                          ])
        let decision = ConsentDecision(decisionType: .explicit,
                                       purposes: ["other"])
        let inspector = ConsentInspector(configuration: config,
                                         decision: decision,
                                         allPurposes: nil)
        let dispatches = [Dispatch(name: "event")]
        queueManager.storeDispatches(dispatches,
                                     enqueueingFor: [ConsentIntegrationManager.id])
        queueManager.onStoreRequest.subscribeOnce { _, _ in
            storeRequest.fulfill()
        }
        consentManager.handleConsentInspectorChange(inspector)
        waitForDefaultTimeout()
    }
}

/**
 * The dispatchers come from the modules, which are empty until a settings pass has created them. A
 * CMP can answer before that happens, since `ConsentIntegrationManager` is built - and subscribes to
 * the inspector - before the first pass runs.
 */
final class ConsentBeforeModulesTests: ConsentIntegrationManagerBaseTests {
    /// No settings pass has created the dispatchers yet.
    lazy var consentManagerWithoutModules = buildConsentManager(cmpAdapter: adapter, modules: .constant([]))

    private func consentedInspector() -> ConsentInspector {
        let configuration = ConsentConfiguration(tealiumPurposeId: "tealium",
                                                 refireDispatchersIds: nil,
                                                 purposes: [:])
        return ConsentInspector(configuration: configuration,
                                decision: ConsentDecision(decisionType: .explicit, purposes: ["tealium"]),
                                allPurposes: nil)
    }

    /// The dispatches held for consent are dequeued, stored for nobody, and then deleted by the `defer`.
    func test_handleConsentInspectorChange_does_not_lose_the_dispatches_when_no_dispatcher_exists_yet() {
        XCTExpectFailure("""
                         Known bug: the dispatches are dequeued from the consent queue, the re-enqueue \
                         no-ops on the empty processors list, and the `defer` deletes them anyway. \
                         Remove this expectation once the deletion only happens after a successful store.
                         """)
        let dispatch = Dispatch(name: "event")
        _ = consentManagerWithoutModules.applyConsent(to: dispatch)
        XCTAssertEqual(queueManager.peekDispatches(for: ConsentIntegrationManager.id, limit: nil).count, 1,
                       "Precondition: the dispatch is held for consent")
        consentManagerWithoutModules.handleConsentInspectorChange(consentedInspector())
        let heldForConsent = queueManager.peekDispatches(for: ConsentIntegrationManager.id, limit: nil)
        let enqueuedForDispatchers = allDispatchersIds.flatMap {
            queueManager.peekDispatches(for: $0, limit: nil)
        }
        XCTAssertEqual(heldForConsent.count + enqueuedForDispatchers.count, 1,
                       "The consented dispatch must be kept, not deleted before it reaches a dispatcher")
    }

    /// `storeDispatches` no-ops on an empty processors list, but the result still claims `accepted`.
    func test_applyConsent_does_not_report_accepted_when_the_dispatch_is_enqueued_for_nobody() {
        XCTExpectFailure("""
                         Known bug: `storeDispatches` no-ops on the empty processors list, so the \
                         dispatch is stored nowhere while the caller is told it was accepted. \
                         Remove this expectation once the empty list is reported as dropped.
                         """)
        // Consented, and no refire dispatcher, so the processors are only the ones from the modules.
        _ = consentManagerWithoutModules
        adapter.applyDecision(ConsentDecision(decisionType: .explicit, purposes: ["tealium"]))
        let result = consentManagerWithoutModules.applyConsent(to: Dispatch(name: "event"))
        let stored = queueManager.peekDispatches(for: ConsentIntegrationManager.id, limit: nil).count
            + allDispatchersIds.flatMap { queueManager.peekDispatches(for: $0, limit: nil) }.count
        if case .accepted = result.status {
            XCTAssertGreaterThan(stored, 0, "Reported as accepted, but the dispatch was stored nowhere")
        }
    }
}

/**
 * `ModuleManager` only publishes the modules at the end of a settings pass, so anything reading
 * `modules.value` while a pass is running is answered with the modules of the *previous* one.
 */
final class ConsentDuringModulesUpdateTests: ConsentIntegrationManagerBaseTests {
    let updatingManager = ModuleManager()
    lazy var updatingConfig = TealiumConfig(account: "test",
                                            profile: "test",
                                            environment: "dev",
                                            modules: [MockDispatcher1.factory(),
                                                      MockDispatcher2.factory(),
                                                      CallbackOnInitModule.factory()],
                                            settingsFile: nil,
                                            settingsUrl: nil)
    lazy var updatingContext = MockContext(moduleManager: updatingManager,
                                           config: updatingConfig,
                                           databaseProvider: databaseProvider,
                                           queue: .main)
    lazy var consentManagerUnderUpdate = buildConsentManager(cmpAdapter: adapter,
                                                             modules: updatingManager.modules)

    private func settings(enabling enabled: [String], disabling disabled: [String] = []) -> SDKSettings {
        var modules = enabled.reduce(into: [String: ModuleSettings]()) { result, moduleType in
            result[moduleType] = ModuleSettings(moduleType: moduleType)
        }
        for moduleType in disabled {
            modules[moduleType] = ModuleSettings(moduleType: moduleType, enabled: false)
        }
        return SDKSettings(modules: modules)
    }

    func test_applyConsent_does_not_enqueue_for_the_dispatchers_of_the_previous_pass() {
        XCTExpectFailure("""
                         Known bug: `dispatchers.value` is read synchronously, so a dispatch handled \
                         during a settings pass is enqueued for the dispatchers of the previous one - \
                         here for the very dispatcher that this pass is disabling. \
                         Remove this expectation once the enqueue waits for the modules to be ready.
                         """)
        addTeardownBlock { CallbackOnInitModule.onInit = nil }
        adapter.applyDecision(ConsentDecision(decisionType: .explicit, purposes: ["tealium"]))
        // First pass: MockDispatcher1 is the only dispatcher.
        updatingManager.updateSettings(context: updatingContext,
                                       settings: settings(enabling: [MockDispatcher1.moduleType]))
        var storedFor: [String]?
        queueManager.onStoreRequest.subscribeOnce { _, processors in
            storedFor = processors
        }
        // Second pass: MockDispatcher1 is replaced by MockDispatcher2, and the module created by this
        // same pass applies consent to an event while the pass is still running.
        CallbackOnInitModule.onInit = { [consentManagerUnderUpdate] in
            _ = consentManagerUnderUpdate.applyConsent(to: Dispatch(name: "event"))
        }
        updatingManager.updateSettings(context: updatingContext,
                                       settings: settings(enabling: [MockDispatcher2.moduleType,
                                                                     CallbackOnInitModule.moduleType],
                                                          disabling: [MockDispatcher1.moduleType]))
        XCTAssertEqual(storedFor, [MockDispatcher2.moduleType],
                       "The dispatch must reach the dispatchers of the pass that is running, not the previous ones")
    }
}
