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
    class override var id: String { "consent" }
    var currentDecision: ConsentDecision?
    var allPurposes: [String] = []
    var trackResult: TrackResult = .accepted

    @ToAnyObservable(TealiumPublisher<TealiumDispatch>())
    var onApplyConsent: TealiumObservable<TealiumDispatch>

    func applyConsent(to dispatch: TealiumDispatch, completion onTrackResult: TrackResultCompletion?) {
        _onApplyConsent.publish(dispatch)
        onTrackResult?(dispatch, trackResult)
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
