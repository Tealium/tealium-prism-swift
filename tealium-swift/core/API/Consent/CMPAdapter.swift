//
//  CMPAdapter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public protocol CMPAdapter {
    var id: String { get }
    var consentDecision: ObservableState<ConsentDecision?> { get }
    var allPurposes: [String] { get }
}
