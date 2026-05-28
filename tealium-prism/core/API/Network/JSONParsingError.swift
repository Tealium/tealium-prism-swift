//
//  JSONParsingError.swift
//  tealium-prism
//
//  Created by Den Guzov on 23/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// Errors thrown when parsing a JSON payload fails.
public enum JSONParsingError: ErrorEnum {
    /// The parsed JSON value is not a dictionary.
    case jsonIsNotADictionary(_ object: Any)
    /// The input string is not valid JSON.
    case invalidJSON(_ error: any Error)
}
