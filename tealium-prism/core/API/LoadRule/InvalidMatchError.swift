//
//  InvalidMatchError.swift
//  tealium-prism-Core-iOS
//
//  Created by Den Guzov on 09/09/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Error to signify that the `Matchable.matches` has failed in an exceptional way,
/// as opposed to having not matched the input.
public protocol InvalidMatchError: Error, CustomStringConvertible {
    var description: String { get }
}
