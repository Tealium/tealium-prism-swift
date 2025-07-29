//
//  MockCMPAdapter.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockCMPAdapter: CMPAdapter {
    let id: String
    @ToAnyObservable<ReplaySubject<ConsentDecision?>>(ReplaySubject<ConsentDecision?>(initialValue: nil))
    var consentDecision: Observable<ConsentDecision?>

    var allPurposes: Set<String>?

    init(id: String = "MockCMP", consentDecision: ConsentDecision?) {
        self.id = id
        applyDecision(consentDecision)
    }

    func applyDecision(_ consentDecision: ConsentDecision?) {
        self._consentDecision.publish(consentDecision)
    }
}
