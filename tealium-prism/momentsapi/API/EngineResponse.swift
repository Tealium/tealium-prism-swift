//
//  EngineResponse.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Response object containing visitor profile data returned by the Moments API.
 */
public struct EngineResponse: Codable, Equatable {
    /// The complete list of audiences the visitor is currently assigned to.
    public let audiences: [String]?
    /// The complete list of badges assigned to the visitor.
    public let badges: [String]?
    /// All AudienceStream `Boolean` attributes currently assigned to the visitor.
    public let flags: [String: Bool]?
    /// All AudienceStream `Date` attributes currently assigned to the visitor, which are millisecond-precise Unix timestamps.
    public let dates: [String: Int64]?
    /// All AudienceStream `Number` attributes currently assigned to the visitor.
    public let metrics: [String: Double]?
    /// All AudienceStream `String` attributes currently assigned to the visitor.
    public let properties: [String: String]?

    public init(audiences: [String]? = nil,
                badges: [String]? = nil,
                flags: [String: Bool]? = nil,
                dates: [String: Int64]? = nil,
                metrics: [String: Double]? = nil,
                properties: [String: String]? = nil) {
        self.audiences = audiences
        self.badges = badges
        self.flags = flags
        self.dates = dates
        self.metrics = metrics
        self.properties = properties
    }
}
