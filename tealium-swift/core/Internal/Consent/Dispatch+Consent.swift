//
//  Dispatch+Consent.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 11/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension Dispatch {
    func applyConsentDecision(_ decision: ConsentDecision) -> Dispatch? {
        let preProcessedPurposes = self.payload
            .getArray(key: ConsentConstants.allPurposesKey, of: String.self)?.compactMap { $0 } ?? []

        var dispatch = self
        let purposes = decision.purposes
        let unprocessedPurposes = purposes.filter { !preProcessedPurposes.contains($0) }
        guard !unprocessedPurposes.isEmpty else { return nil }
        dispatch.enrich(data: [
            ConsentConstants.unprocessedPurposesKey: unprocessedPurposes,
            ConsentConstants.processedPurposesKey: preProcessedPurposes,
            ConsentConstants.allPurposesKey: purposes,
            ConsentConstants.consentTypeKey: decision.decisionType.rawValue,
        ])
        return dispatch
    }

    func matchesConfiguration(_ configuration: ConsentConfiguration, forDispatcher dispatcherId: String) -> Bool {
        let dispatcherHasAtLeastOneRequiredPurpose = configuration.hasAtLeastOneRequiredPurposeForDispatcher(dispatcherId)
        guard let consentedPurposes = self.payload
            .getArray(key: ConsentConstants.allPurposesKey, of: String.self),
              !consentedPurposes.isEmpty,
              dispatcherHasAtLeastOneRequiredPurpose else {
            return false
        }
        let requiredPurposes = configuration.purposes
            .values
            .filter { $0.dispatcherIds.contains(dispatcherId) }
            .map { $0.purposeId }
        return requiredPurposes.allSatisfy(consentedPurposes.contains(_:))
    }

    func hasAlreadyProcessedPurposes() -> Bool {
        guard let processedPurposes = payload.getArray(key: ConsentConstants.processedPurposesKey,
                                                       of: String.self) else {
            return false
        }
        return !processedPurposes.compactMap { $0 }.isEmpty
    }
}
