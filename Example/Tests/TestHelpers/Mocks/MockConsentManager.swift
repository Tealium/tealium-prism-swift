//
//  MockConsentManager.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 01/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockConsentManager: MockModule, ConsentManager {
    class override var id: String { ConsentModule.id }
    var currentDecision: ConsentDecision?
    var allPurposes: [String] = []
    var acceptTrack: Bool = true
    func trackResultBuilder(dispatch: Dispatch) -> TrackResult {
        if self.acceptTrack {
            .accepted(dispatch)
        } else {
            .dropped(dispatch)
        }
    }

    @ToAnyObservable(BasePublisher<Dispatch>())
    var onApplyConsent: Observable<Dispatch>

    func applyConsent(to dispatch: Dispatch, completion onTrackResult: TrackResultCompletion?) {
        _onApplyConsent.publish(dispatch)
        onTrackResult?(trackResultBuilder(dispatch: dispatch))
    }

    func tealiumConsented(forPurposes purposes: [String]) -> Bool {
        purposes.contains("tealium")
    }

    func allPurposesMatch(consentDecision: ConsentDecision) -> Bool {
        consentDecision.matchAll(allPurposes)
    }

    func getConsentDecision() -> ConsentDecision? {
        currentDecision
    }
}
