//
//  MockCMPAdapter.swift
//  tealium-prism_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism

class MockCMPAdapter: CMPAdapter {
    let id: String
    @ReplaySubject<ConsentDecision?>(nil)
    var consentDecision

    var allPurposes: Set<String>?

    init(id: String = "MockCMP", consentDecision: ConsentDecision?) {
        self.id = id
        applyDecision(consentDecision)
    }

    func applyDecision(_ consentDecision: ConsentDecision?) {
        self._consentDecision.publish(consentDecision)
    }
}
