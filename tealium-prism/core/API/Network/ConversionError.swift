//
//  ConversionError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum ConversionError: ErrorEnum {
    /// The provided URL could not be converted to a valid `URL`.
    case invalidUrl(_ url: URLConvertible)
}
