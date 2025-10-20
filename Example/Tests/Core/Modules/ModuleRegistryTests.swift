//
//  ModuleRegistryTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 14/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism
import XCTest

class ModuleRegistryTests: XCTestCase {
    let registry = ModuleRegistry.shared

    // When creating new modules, make sure to add them here
    let installedModules = [
        Modules.Types.appData,
        Modules.Types.collect,
        Modules.Types.dataLayer,
        Modules.Types.deviceData,
        Modules.Types.trace,
        Modules.Types.deepLink,
        Modules.Types.tealiumData,
        Modules.Types.connectivityData,
        Modules.Types.timeData,
        Modules.Types.lifecycle
    ]

    // When making a mandatory module, make sure to add them here as well
    let mandatoryModules = [
        Modules.Types.dataLayer,
        Modules.Types.tealiumData
    ]

    func test_defaultModules_contain_all_installed_modules() {
        let defaultModules = registry.defaultModules
        XCTAssertEqual(defaultModules.count, installedModules.count)
        XCTAssertEqual(Set(defaultModules.map { $0.moduleType }), Set(installedModules))
    }

    func test_only_mandatory_modules_contain_enforced_settings() {
        let modulesWithSettings = registry.defaultModules
            .filter { !$0.getEnforcedSettings().isEmpty }
            .map { $0.moduleType }
        XCTAssertEqual(modulesWithSettings.count, mandatoryModules.count)
        XCTAssertEqual(Set(modulesWithSettings), Set(mandatoryModules))
    }
}
