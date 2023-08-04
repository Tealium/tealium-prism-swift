//
//  ParsingError.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

enum ParsingError: Error {
    case invalidUrl(_ url: URLConvertible)
    case nonConvertibleToJSONObject(_ object: Any)
    case jsonIsNotADictionary(_ object: Any)
}
