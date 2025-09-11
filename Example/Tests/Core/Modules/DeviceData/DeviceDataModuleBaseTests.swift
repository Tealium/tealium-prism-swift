//
//  DeviceDataModuleBaseTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 30/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class DeviceDataModuleBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let networkHelper = MockNetworkHelper()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var transformerRegistry = TransformerCoordinator(transformers: .constant([]),
                                                          transformations: .constant([]),
                                                          moduleMappings: .constant([:]),
                                                          queue: queue,
                                                          logger: nil)
    lazy var context = MockContext(modulesManager: manager,
                                   config: config,
                                   transformerRegistry: transformerRegistry,
                                   databaseProvider: dbProvider,
                                   networkHelper: networkHelper,
                                   queue: queue)
    let dispatchContext = DispatchContext(source: .application, initialData: [:])
    let disposer = AutomaticDisposer()

    override func setUp() {
        manager.updateSettings(context: context, settings: SDKSettings([:]))
    }
}
