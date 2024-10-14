//
//  DataItemConverter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// Assign this protocol to a class that can be converted from a `DataItem`
public protocol DataItemConverter<Convertible> {
    associatedtype Convertible
    /// Converts the provided `DataItem` to an instance of `Self`, if the conversion succeds.
    func convert(dataItem: DataItem) -> Convertible?
}
