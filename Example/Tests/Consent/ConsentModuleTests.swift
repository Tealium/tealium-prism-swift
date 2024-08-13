//
//  ConsentModuleTests.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConsentModuleTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let modulesManager = ModulesManager()
    lazy var settings: [String: Any] = [ConsentModule.id: ["enabled": true]]
    lazy var _coreSettings = StateSubject(CoreSettings(coreDictionary: settings))
    var coreSettings: ObservableState<CoreSettings> {
        _coreSettings.toStatefulObservable()
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImplementation.queueProcessors(from: modulesManager.modules),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: TimeFrame(unit: .days, interval: 1)),
                                             coreSettings: coreSettings)
    @StateSubject([])
    var scopedTransformations: ObservableState<[ScopedTransformation]>
    lazy var transformerCoordinator = TransformerCoordinator(registeredTransformers: [],
                                                             scopedTransformations: scopedTransformations,
                                                             queue: .main)
    @StateSubject(ConsentSettings(moduleSettings: [:]))
    var consentSettings: ObservableState<ConsentSettings>
    func buildConsentManager(cmpIntegration: CMPIntegration) -> ConsentManager {
        return ConsentModule(queueManager: queueManager,
                             modules: modulesManager.modules,
                             transformerRegistry: transformerCoordinator,
                             cmpIntegration: cmpIntegration,
                             consentSettings: _consentSettings)
    }
    let completionCalledDescription = "Completion was called"

    func test_applyConsent_runs_completion_with_dropped_result_and_original_dispatch_when_explicitly_not_tealium_consented() {
        let integration = MockCMPIntegration(consentDecision: ObservableState(variableSubject: StateSubject(ConsentDecision(decisionType: .explicit, purposes: []))))
        let consentManager: ConsentManager = buildConsentManager(cmpIntegration: integration)
        let completionCalled = expectation(description: completionCalledDescription)
        consentManager.applyConsent(to: TealiumDispatch(name: "event1")) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .dropped)
            XCTAssertEqual(dispatch.eventData.count, 2)
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_applyConsent_runs_completion_with_accepted_result_and_original_dispatch_when_implicitly_not_tealium_consented() {
        let integration = MockCMPIntegration(consentDecision: ObservableState(variableSubject: StateSubject(ConsentDecision(decisionType: .implicit, purposes: []))))
        let consentManager: ConsentManager = buildConsentManager(cmpIntegration: integration)
        let completionCalled = expectation(description: completionCalledDescription)
        consentManager.applyConsent(to: TealiumDispatch(name: "event1")) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .accepted)
            XCTAssertEqual(dispatch.eventData.count, 2)
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_applyConsent_runs_completion_with_accepted_result_and_consented_dispatch_when_tealium_consented() {
        let integration = MockCMPIntegration(consentDecision: ObservableState(variableSubject: StateSubject(ConsentDecision(decisionType: .explicit, purposes: ["tealium"]))))
        let consentManager: ConsentManager = buildConsentManager(cmpIntegration: integration)
        let completionCalled = expectation(description: completionCalledDescription)
        consentManager.applyConsent(to: TealiumDispatch(name: "event1")) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .accepted)
            XCTAssertNotEqual(dispatch.eventData.count, 2)
            XCTAssertNotNil(dispatch.eventData["consent_type"])
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_apply_consent_runs_completion_with_dropped_result_and_original_dispatch_when_unprocessed_purposes_empty() {
        let integration = MockCMPIntegration(consentDecision: ObservableState(variableSubject: StateSubject(ConsentDecision(decisionType: .explicit, purposes: ["tealium"]))))
        let consentManager: ConsentManager = buildConsentManager(cmpIntegration: integration)
        let completionCalled = expectation(description: completionCalledDescription)
        var dispatch = TealiumDispatch(name: "event1")
        dispatch.enrich(data: ["purposes_with_consent_all": ["tealium"]]) // this is gonna be the 3rd property of eventData...
        consentManager.applyConsent(to: dispatch) { dispatch, result in
            completionCalled.fulfill()
            XCTAssertEqual(result, .dropped)
            XCTAssertEqual(dispatch.eventData.count, 3) // ...that's why 3 is here
        }
        waitForExpectations(timeout: 1.0)
    }
}
