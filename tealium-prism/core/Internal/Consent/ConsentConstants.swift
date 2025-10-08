//
//  ConsentConstants.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 01/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension TealiumDataKey {
    static let processedPurposes = "tci.purposes_with_consent_processed"
    static let unprocessedPurposes = "tci.purposes_with_consent_unprocessed"
    static let allConsentedPurposes = "tci.purposes_with_consent_all"
    static let consentType = "tci.consent_type"
}

enum ConsentConstants {
    static let refireIdPostfix = "-refire"
}
