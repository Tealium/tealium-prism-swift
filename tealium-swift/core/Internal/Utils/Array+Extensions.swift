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

    func diff<T: Equatable>(_ other: Self, by key: KeyPath<Element, T>) -> Self {
        self.filter { element in
            !other.contains(where: { $0[keyPath: key] == element[keyPath: key] })
        }
    }

    func partitioned(by belongsInFirstPartition: (Element) throws -> Bool) rethrows -> (Self, Self) {
        var first = [Element]()
        var second = [Element]()
        for element in self {
            if try belongsInFirstPartition(element) {
                first.append(element)
            } else {
                second.append(element)
            }
        }
        return (first, second)
    }
}
