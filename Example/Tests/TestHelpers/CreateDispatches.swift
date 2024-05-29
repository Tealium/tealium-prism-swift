//
//  CreateDispatches.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 29/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

public func createDispatches(amount: Int) -> [TealiumDispatch] {
    (1...amount).map { count in
        TealiumDispatch(name: "event\(count)")
    }
}
