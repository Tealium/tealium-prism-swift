//
//  CmpAdapter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * The `CmpAdapter` provides a consistent interface with external Consent Management
 * Providers (Cmp).
 */
public protocol CmpAdapter {
    /**
     * The unique identifier for this `CmpAdapter`.
     */
    var id: String { get }

    /**
     * An observable flow of the `ConsentDecision`s from the visitor.
     *
     * Subscriptions to this observable will always come from the `TealiumQueue.worker`.
     */
    var consentDecision: Observable<ConsentDecision?> { get }

    /**
     * Returns all possible purposes from the Cmp.
     */
    var allPurposes: [String] { get }
}
