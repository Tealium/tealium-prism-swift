//
//  ConsentConstants.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 01/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension TealiumDataKey {
    static let processedPurposes = "purposes_with_consent_processed"
    static let unprocessedPurposes = "purposes_with_consent_unprocessed"
    static let allConsentedPurposes = "purposes_with_consent_all"
    static let consentType = "consent_type"
}

enum ConsentConstants {
    static let refireIdPostfix = "-refire"
}
