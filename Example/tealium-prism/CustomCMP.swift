//
//  CustomCMP.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism

class CustomCMP: CMPAdapter, ObservableObject {
    enum Purposes: String, CaseIterable {
        case tealium
        case tracking
        case functional
    }
    let id = "custom"
    static let defaults = UserDefaults.standard
    var currentDecision: ConsentDecision {
        _consentDecision.value
    }

    let _consentDecision = StateSubject<ConsentDecision>(CustomCMP.readDecision())
    var consentDecision: Observable<ConsentDecision?> {
        _consentDecision.asObservable()
            .map { $0 }
            .subscribeOn(.main)
    }

    let allPurposes: Set<String>? = Set(Purposes.allCases.map { $0.rawValue })

    func applyConsent(_ consentDecision: ConsentDecision) {
        Self.saveDecision(consentDecision)
        _consentDecision.onNext(consentDecision)
        self.objectWillChange.send()
    }

    static func readDecision() -> ConsentDecision {
        let decisionType = defaults.decisionType ?? .implicit
        let purposes = defaults.purposes ?? []
        return ConsentDecision(decisionType: decisionType, purposes: Set(purposes))
    }

    static func saveDecision(_ decision: ConsentDecision) {
        defaults.decisionType = decision.decisionType
        defaults.purposes = Array(decision.purposes)
    }
}

extension UserDefaults {
    var decisionType: ConsentDecision.DecisionType? {
        get {
            string(forKey: "decision_type").flatMap { ConsentDecision.DecisionType(rawValue: $0) }
        }
        set {
            set(newValue?.rawValue, forKey: "decision_type")
        }
    }
    var purposes: [String]? {
        get {
            array(forKey: "purposes") as? [String]
        }
        set {
            set(newValue, forKey: "purposes")
        }
    }
}
