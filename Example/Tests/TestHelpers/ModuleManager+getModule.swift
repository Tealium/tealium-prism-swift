//
//  ModuleManager+getModule.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

extension ModuleManager {
    func getModule<T: Module>(_ module: T.Type = T.self) -> T? {
        modules.value.lazy.compactMap { $0 as? T }.first
    }

    func mockReady() {
        updateSettings(context: mockContext, settings: SDKSettings())
    }
}
