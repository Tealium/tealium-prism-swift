//
//  ConsentIntegrationManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConsentIntegrationManagerTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let modulesManager = ModulesManager(queue: TealiumQueue.worker)

    @StateSubject(CoreSettings())
    var coreSettings
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: modulesManager.modules, addingConsent: true),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: TimeFrame(unit: .days, interval: 1)),
                                             coreSettings: coreSettings,
                                             logger: nil)
    @StateSubject([])
    var transformations: ObservableState<[TransformationSettings]>
    lazy var transformerCoordinator = TransformerCoordinator(transformers: .constant([]),
                                                             transformations: transformations,
                                                             moduleMappings: .constant([:]),
                                                             queue: .main)
    @StateSubject(ConsentSettings(configurations: ["MockCMP": ConsentConfiguration(tealiumPurposeId: "tealium",
                                                                                   refireDispatchersIds: [],
                                                                                   purposes: [:])]))
    var consentSettings: ObservableState<ConsentSettings?>

    let adapter = MockCMPAdapter(consentDecision: nil)

    lazy var consentManager = buildConsentManager(cmpAdapter: adapter)

    func buildConsentManager(cmpAdapter: CMPAdapter) -> ConsentManager {
        let cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                   cmpAdapter: cmpAdapter,
                                                   queue: .main)
        return ConsentIntegrationManager(queueManager: queueManager,
                                         modules: modulesManager.modules,
                                         consentSettings: consentSettings,
                                         cmpSelector: cmpSelector)
    }
    let completionCalledDescription = "Completion was called"

    func applyDecision(decisionType: ConsentDecision.DecisionType, purposes: [String]) {
        adapter.applyDecision(ConsentDecision(decisionType: decisionType, purposes: purposes))
    }

    func test_applyConsent_returns_dropped_result_and_original_dispatch_when_explicitly_not_tealium_consented() {
        applyDecision(decisionType: .explicit, purposes: [])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        switch result {
        case let .dropped(dispatch):
            XCTAssertEqual(dispatch.payload.count, 3)
        case .accepted:
            XCTFail("Expected to be dropped but got accepted")
        }
    }

    func test_applyConsent_returns_accepted_result_and_original_dispatch_when_implicitly_not_tealium_consented() {
        applyDecision(decisionType: .implicit, purposes: [])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        switch result {
        case .dropped:
            XCTFail("Expected to be accepted but got dropped")
        case let .accepted(dispatch):
            XCTAssertEqual(dispatch.payload.count, 3)
        }
    }

    func test_applyConsent_returns_accepted_result_and_consented_dispatch_when_tealium_consented() {
        applyDecision(decisionType: .explicit, purposes: ["tealium"])
        let result = consentManager.applyConsent(to: Dispatch(name: "event1"))
        switch result {
        case .dropped:
            XCTFail("Expected to be accepted but got dropped")
        case let .accepted(dispatch):
            XCTAssertNotEqual(dispatch.payload.count, 3)
            XCTAssertNotNil(dispatch.payload.getDataItem(key: "consent_type"))
        }
    }

    func test_applyConsent_returns_dropped_result_and_original_dispatch_when_unprocessed_purposes_empty() {
        applyDecision(decisionType: .explicit, purposes: ["tealium"])
        var dispatch = Dispatch(name: "event1")
        dispatch.enrich(data: ["purposes_with_consent_all": ["tealium"]]) // this is gonna be the 3rd property of payload...
        let result = consentManager.applyConsent(to: dispatch)
        switch result {
        case let .dropped(dispatch):
            XCTAssertEqual(dispatch.payload.count, 4) // ...that's why 4 is here
        case .accepted:
            XCTFail("Expected to be dropped but got accepted")
        }
    }
}
