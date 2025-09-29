//
//  Weak.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct Weak<T> where T: AnyObject {
    weak var value: T?
}
