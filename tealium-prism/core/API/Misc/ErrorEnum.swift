//
//  ErrorEnum.swift
//  tealium-prism
//
//  Created by Den Guzov on 09/09/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol that adds a readable localizedDescription to error enums.
public protocol ErrorEnum: Error {}

/// Add default localizedDescription
public extension ErrorEnum {
    var localizedDescription: String {
        "\(type(of: self)).\(self)"
    }
}
