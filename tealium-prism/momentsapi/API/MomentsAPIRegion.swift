//
//  MomentsAPIRegion.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if momentsapi
import TealiumPrismCore
#endif

/**
 * Enum representing the available regions for the Moments API.
 * 
 * The region determines which Tealium AudienceStream instance the API calls are made against.
 * Use `.custom(_:)` to support future regions that may be released without requiring an SDK update.
 */
public enum MomentsAPIRegion: DataInputConvertible, Equatable, RawRepresentable {
    /// Germany region
    case germany
    /// United States East region
    case usEast
    /// Sydney region
    case sydney
    /// Oregon region
    case oregon
    /// Tokyo region
    case tokyo
    /// Hong Kong region
    case hongKong
    /// Custom region for future regions
    case custom(String)

    /// AWS region string constants
    enum AWSRegion {
        static let euCentral1 = "eu-central-1"
        static let usEast1 = "us-east-1"
        static let apSoutheast2 = "ap-southeast-2"
        static let usWest2 = "us-west-2"
        static let apNortheast1 = "ap-northeast-1"
        static let apEast1 = "ap-east-1"
    }

    /// The raw string value of the region
    public var rawValue: String {
        switch self {
        case .germany: return AWSRegion.euCentral1
        case .usEast: return AWSRegion.usEast1
        case .sydney: return AWSRegion.apSoutheast2
        case .oregon: return AWSRegion.usWest2
        case .tokyo: return AWSRegion.apNortheast1
        case .hongKong: return AWSRegion.apEast1
        case .custom(let value): return value
        }
    }

    /// Creates a region from a raw string value
    public init?(rawValue: String) {
        let lowercased = rawValue.lowercased()
        switch lowercased {
        case AWSRegion.euCentral1: self = .germany
        case AWSRegion.usEast1: self = .usEast
        case AWSRegion.apSoutheast2: self = .sydney
        case AWSRegion.usWest2: self = .oregon
        case AWSRegion.apNortheast1: self = .tokyo
        case AWSRegion.apEast1: self = .hongKong
        default: self = .custom(rawValue)
        }
    }

    public func toDataInput() -> any DataInput {
        self.rawValue
    }
}
