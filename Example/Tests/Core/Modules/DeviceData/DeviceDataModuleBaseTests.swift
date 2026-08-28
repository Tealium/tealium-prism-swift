//
//  DeviceDataModuleBaseTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 30/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class DeviceDataModuleBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let networkHelper = MockNetworkHelper()
    lazy var manager = ModuleManager(queue: queue)
    lazy var onManager = ReplaySubject<ModuleManager?>(manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var transformerCoordinator = TransformerCoordinator(transformers: .constant([]),
                                                             transformations: .constant([]),
                                                             queue: queue,
                                                             logger: nil)
    lazy var context = MockContext(moduleManager: manager,
                                   config: config,
                                   transformerRegistrar: transformerCoordinator,
                                   databaseProvider: dbProvider,
                                   networkHelper: networkHelper,
                                   queue: queue)
    let dispatchContext = DispatchContext(source: .application, initialData: [:])
    let disposer = AutomaticDisposer()

    override func setUp() {
        manager.updateSettings(context: context, settings: SDKSettings([:]))
    }
}
