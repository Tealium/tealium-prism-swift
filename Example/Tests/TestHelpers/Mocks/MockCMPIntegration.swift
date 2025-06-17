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
    @StateSubject(nil)
    var consentDecision: ObservableState<ConsentDecision?>

    var allPurposes: [String] {
        return consentDecision.value?.purposes ?? []
    }

    init(id: String = "MockCMP", consentDecision: ConsentDecision?) {
        self.id = id
        applyDecision(consentDecision)
    }

    func applyDecision(_ consentDecision: ConsentDecision?) {
        self._consentDecision.value = consentDecision
    }
}
