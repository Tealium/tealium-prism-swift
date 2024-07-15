//
//  MockCMPIntegration.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 10/06/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockCMPIntegration: CMPIntegration {
    let consentDecision: TealiumSwift.ObservableState<TealiumSwift.ConsentDecision?>

    func allPurposes() -> [String] {
        return consentDecision.value?.purposes ?? []
    }

    init(consentDecision: TealiumSwift.ObservableState<TealiumSwift.ConsentDecision?>) {
        self.consentDecision = consentDecision
    }
}
