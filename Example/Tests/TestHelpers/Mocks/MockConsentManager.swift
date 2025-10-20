//
//  MockConsentManager.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 01/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockConsentManager: ConsentManager {

    let _onConfigurationSelected = ReplaySubject<ConsentConfiguration?>()
    var onConfigurationSelected: Observable<ConsentConfiguration?> {
        _onConfigurationSelected.asObservable()
    }

    var unrecoverableConsentError: Error?

    var tealiumPurposeExplicitlyBlocked: Bool {
        currentDecision?.isMatchingAllPurposes(in: ["tealium"]) != true
    }
    var currentDecision: ConsentDecision? = ConsentDecision(decisionType: .implicit, purposes: ["tealium"])
    var allPurposes: [String] = []
    var acceptTrack: Bool = true
    func trackResultBuilder(dispatch: Dispatch) -> TrackResult {
        if self.acceptTrack {
            .accepted(dispatch, info: "Mock Accepted")
        } else {
            .dropped(dispatch, reason: "Mock Dropped")
        }
    }

    @Subject<Dispatch> var onApplyConsent

    func applyConsent(to dispatch: Dispatch) -> TrackResult {
        _onApplyConsent.publish(dispatch)
        return trackResultBuilder(dispatch: dispatch)
    }

    func filterDispatches(_ dispatches: [Dispatch], matchingPurposesForDispatcher dispatcher: Dispatcher) -> Observable<[Dispatch]> {
        Observables.just(dispatches)
    }

    func getConsentDecision() -> ConsentDecision? {
        currentDecision
    }
}
