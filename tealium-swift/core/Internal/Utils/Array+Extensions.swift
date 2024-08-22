//
//  Array+Extensions.swift
//  tealium-swift
//
//  Created by Denis Guzov on 10/07/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension Array {
    mutating func removeFirst(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        if let index = try self.firstIndex(where: shouldBeRemoved) {
            self.remove(at: index)
        }
    }
}
