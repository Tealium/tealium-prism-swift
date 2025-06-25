//
//  CMPAdapter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * The `CMPAdapter` provides a consistent interface with external Consent Management
 * Providers (CMP).
 */
public protocol CMPAdapter {
    /**
     * The unique identifier for this `CMPAdapter`.
     */
    var id: String { get }

    /**
     * An observable flow of the `ConsentDecision`s from the visitor.
     *
     * Subscriptions to this observable will always come from the `TealiumQueue.worker`.
     */
    var consentDecision: Observable<ConsentDecision?> { get }

    /**
     * Returns all possible purposes from the CMP.
     */
    var allPurposes: [String] { get }
}
