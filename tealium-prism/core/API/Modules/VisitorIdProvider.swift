//
//  VisitorIdProvider.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/// Synchronous access to the visitor ID.
///
/// Available through ``ModuleManager`` while visitor ID handling is enabled.
public protocol VisitorIdProvider {
    /// The current visitor ID, updated on every change.
    var visitorId: ObservableState<String> { get }
}
