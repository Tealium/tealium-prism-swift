//
//  DataItemConverter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// Classes that implement this protocol should be able to reconstruct an object of type `Convertible` from
/// a given `DataItem`, on the assumption that the `DataItem` accurately describes all
/// components required to create a new instance of type `Convertible`.
public protocol DataItemConverter<Convertible> {
    /// The type that this converter can produce from a DataItem.
    associatedtype Convertible
    /// Converts the provided `DataItem` to an instance of `Convertible`, if the conversion succeeds.
    func convert(dataItem: DataItem) -> Convertible?
}
