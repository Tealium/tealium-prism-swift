//
//  DataInput+Extensions.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

extension NSNull: DataInput, DataInputConvertible {}
extension Decimal: DataInput, DataInputConvertible {}
extension Double: DataInput, DataInputConvertible {}
extension Float: DataInput, DataInputConvertible {}
extension Int: DataInput, DataInputConvertible {}
extension Int64: DataInput, DataInputConvertible {}
extension Bool: DataInput, DataInputConvertible {}
extension String: DataInput, DataInputConvertible {}
extension NSNumber: DataInput, DataInputConvertible {}
extension Array: DataInput where Element == DataInput {}
extension Dictionary: DataInput where Key == String, Value == DataInput { }

extension Optional: DataInputConvertible where Wrapped: DataInputConvertible {
    public func toDataInput() -> DataInput {
        self?.toDataInput() ?? NSNull()
    }
}
public extension DataInputConvertible where Self: DataInput {
    func toDataInput() -> DataInput {
        self
    }
}
extension Array: DataInputConvertible where Element: DataInputConvertible {
    public func toDataInput() -> DataInput {
        self.map { $0.toDataInput() }
    }
}
extension Dictionary: DataInputConvertible where Key == String, Value: DataInputConvertible {
    public func toDataInput() -> DataInput {
        self.mapValues { $0.toDataInput() }
    }
}
