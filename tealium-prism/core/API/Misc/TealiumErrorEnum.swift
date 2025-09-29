//
//  TealiumErrorEnum.swift
//  tealium-prism-Core-iOS
//
//  Created by Den Guzov on 09/09/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumErrorEnum: Error {}

// Add default localizedDescription
extension TealiumErrorEnum {
    var localizedDescription: String {
        return "\(type(of: self)).\(self)"
    }
}
