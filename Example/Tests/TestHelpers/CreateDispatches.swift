//
//  CreateDispatches.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 29/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism

public func createDispatches(amount: Int) -> [Dispatch] {
    (1...amount).map { count in
        Dispatch(name: "event\(count)")
    }
}
