//
//  ConsentIntegrationManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class ConsentIntegrationManagerBaseTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let allDispatchers = [MockDispatcher1(), MockDispatcher2()]
    var allDispatchersIds: [String] {
        allDispatchers.map { $0.id }
    }
    lazy var modulesManager = ModulesManager(queue: TealiumQueue.worker,
                                             initialModules: allDispatchers)

    @StateSubject(CoreSettings())
    var coreSettings
    lazy var queueManager = buildQueueManager()
    func buildQueueManager() -> MockQueueManager {
        let processors = TealiumImpl.queueProcessors(from: modulesManager.modules,
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
    lazy var transformerCoordinator = TransformerCoordinator(transformers: .constant([]),
                                                             transformations: transformations,
                                                             moduleMappings: .constant([:]),
                                                             queue: .main)

    static func buildConsentSettings() -> ConsentSettings {
        let configuration = ConsentConfiguration(tealiumPurposeId: "tealium",
                                                 refireDispatchersIds: [],
                                                 purposes: [:])
        return ConsentSettings(configurations: ["MockCMP": configuration])
    }
    @StateSubject(buildConsentSettings())
    var consentSettings: ObservableState<ConsentSettings?>

    let adapter = MockCMPAdapter(consentDecision: nil)

    lazy var consentManager = buildConsentManager(cmpAdapter: adapter)

    func buildConsentManager(cmpAdapter: CMPAdapter) -> ConsentIntegrationManager {
        let cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                   cmpAdapter: cmpAdapter,
                                                   queue: .main)
        return ConsentIntegrationManager(queueManager: queueManager,
                                         modules: modulesManager.modules,
                                         consentSettings: consentSettings,
                                         cmpSelector: cmpSelector,
                                         logger: nil)
    }
}

final class ConsentIntegrationManagerTests: ConsentIntegrationManagerBaseTests {
    let completionCalledDescription = "Completion was called"

    func applyDecision(decisionType: ConsentDecision.DecisionType, purposes: [String]) {
        adapter.applyDecision(ConsentDecision(decisionType: decisionType, purposes: purposes))
    }

    func test_applyConsent_returns_dropped_result_and_original_dispatch_when_explicitly_not_tealium_consented() {
        applyDecision(decisionType: .explicit, purposes: [])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        XCTAssertTrackResultIsDropped(result) { dispatch in
            XCTAssertEqual(dispatch.payload.count, 3)
        }
    }

    func test_applyConsent_returns_accepted_result_and_original_dispatch_when_implicitly_not_tealium_consented() {
        applyDecision(decisionType: .implicit, purposes: [])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        XCTAssertTrackResultIsAccepted(result) { dispatch in
            XCTAssertEqual(dispatch.payload.count, 3)
        }
    }

    func test_applyConsent_returns_accepted_result_and_consented_dispatch_when_tealium_consented() {
        applyDecision(decisionType: .explicit, purposes: ["tealium"])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        XCTAssertTrackResultIsAccepted(result) { dispatch in
            XCTAssertNotEqual(dispatch.payload.count, 3)
            XCTAssertNotNil(dispatch.payload.getDataItem(key: "consent_type"))
        }
    }

    func test_applyConsent_returns_dropped_result_and_original_dispatch_when_unprocessed_purposes_empty() {
        applyDecision(decisionType: .explicit, purposes: ["tealium"])
        var dispatch = Dispatch(name: "event1")
        dispatch.enrich(data: ["purposes_with_consent_all": ["tealium"]]) // this is gonna be the 3rd property of payload...
        let result = consentManager.applyConsent(to: dispatch)
        XCTAssertTrackResultIsDropped(result) { dispatch in
            XCTAssertEqual(dispatch.payload.count, 4) // ...that's why 4 is here
        }
    }

    func test_enqueueDispatches_are_normally_stored_for_all_dispatchers() {
        let dispatchesStored = expectation(description: "Dispatches are stored")
        let dispatches = [
            Dispatch(name: "event1"),
            Dispatch(name: "event2"),
            Dispatch(name: "event3")
        ]
        let refireDispatchers = ["dispatcher1", "dispatcher2"]
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
        let refireDispatchers = ["dispatcher1", "dispatcher2"]
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
        let refireDispatchers = ["dispatcher1", "dispatcher2"]
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
        let dispatches = [Dispatch(name: "event", data: [
            TealiumDataKey.allConsentedPurposes: ["some_purpose"]
        ])]
        queueManager.storeDispatches(dispatches,
                                     enqueueingFor: [ConsentIntegrationManager.id])
        queueManager.onStoreRequest.subscribeOnce { storedDispatches, refireDispatchers in
            XCTAssertEqual(storedDispatches.map { $0.id },
                           dispatches.map { $0.id + "-refire" })
            XCTAssertEqual(refireDispatchers, ["refireDispatcher"])
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
