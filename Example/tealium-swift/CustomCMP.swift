//
//  CustomCMP.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumSwift

class CustomCMP: CMPAdapter, ObservableObject {
    let id = "custom"
    static let defaults = UserDefaults.standard
    var currentDecision: ConsentDecision {
        guard let lastDecision = _consentDecision.publisher.last() as? ConsentDecision else {
            return Self.readDecision()
        }
        return lastDecision
    }
    @ToAnyObservable<ReplaySubject<ConsentDecision?>>(ReplaySubject<ConsentDecision?>(initialValue: CustomCMP.readDecision()))
    var consentDecision: Observable<ConsentDecision?>

    let allPurposes: [String]? = ["tealium", "tracking", "functional"]

    func applyConsent(_ consentDecision: ConsentDecision) {
        Self.saveDecision(consentDecision)
        _consentDecision.publish(consentDecision)
        self.objectWillChange.send()
    }

    static func readDecision() -> ConsentDecision {
        let decisionType = defaults.decisionType ?? .implicit
        let purposes = defaults.purposes ?? []
        return ConsentDecision(decisionType: decisionType, purposes: purposes)
    }

    static func saveDecision(_ decision: ConsentDecision) {
        defaults.decisionType = decision.decisionType
        defaults.purposes = decision.purposes
    }
}

extension UserDefaults {
    var decisionType: ConsentDecision.DecisionType? {
        get {
            guard let type = string(forKey: "decision_type") else {
                return nil
            }
            return ConsentDecision.DecisionType(rawValue: type)
        }
        set {
            set(newValue?.rawValue, forKey: "decision_type")
        }
    }
    var purposes: [String]? {
        get {
            guard let purposes = array(forKey: "purposes") as? [String] else {
                return nil
            }
            return purposes
        }
        set {
            set(newValue, forKey: "purposes")
        }
    }
}
