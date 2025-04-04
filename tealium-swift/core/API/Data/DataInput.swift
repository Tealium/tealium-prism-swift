//
//  DataInput.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * `DataInput` is a protocol used to limit the type of data that can be sent to Tealium to later serialize it into JSON.
 *
 * - Warning: Do not conform custom types to the `DataInput` protocol or it will defeat the purpose of this protocol.
 *
 * Converting a custom object to a `DataInput` can be done easily by adopting the `DataInputConverible` protocol
 * and implementing the `toDataInput` method for a safe conversion.
 *
 * Valid `DataInput` can only be:
 * - a String
 * - a Number: Int, Int64, Double, Float, Decimal, NSNumber
 * - a Bool
 * - an Array or Dictionary containing only Strings, Numbers or Booleans or other nested Arrays and Dictionaries containing other valid `DataInput`
 *
 * - Warning: Non conforming floats like `Double.nan` or `Float.infinity` will be silently converted to strings "NaN" and "Infinity" (or "-Infinity" for negative "Infinity") upon serialization inside of the library.
 */
public protocol DataInput { }

/**
 * Use this protocol to convert custom types to a valid `DataInput`.
 *
 * This is particularly useful for types like enums or objects that can be safely represented with a Dictionary or an Array or a combination of nested Dictionaries and Arrays.
 * Everything that is not a Dictionary or an Array, including the elements contained in those collections, need to be one of the supported `DataInput`.
 *
 * For cases in which you have only nested Arrays and Dictionaries that only contain valid `DataInput`,
 * implementing this protocol is not necessary and you can just wrap them with the prebuilt `DataItem` wrapper.
 *
 * Although not preferrable, you can make any `Encodable` type a `DataInputConvertible` by wrappping it with `DataItem(serializing:)`.
 * Note that this method can fail, so you must handle the eventual `EncodingError` that can be thrown in case of failure.
 */
public protocol DataInputConvertible {
    /// Converts this object to a valid `DataInput`.
    func toDataInput() -> DataInput
}
