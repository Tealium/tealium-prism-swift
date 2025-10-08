//
//  DeepLinkBaseTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class DeepLinkBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = TraceWrapper(moduleProxy: ModuleProxy(queue: queue,
                                                             onModulesManager: onManager.asObservable()))

    func context() -> TealiumContext {
        MockContext(modulesManager: manager,
                    config: config,
                    tracker: tracker,
                    databaseProvider: dbProvider,
                    queue: queue)
    }
    var deepLink: DeepLinkModule!
    let dispatchContext = DispatchContext(source: .application, initialData: [:])
    let testTraceId = "testTraceId"

    override func setUp() {
        config.modules = [Modules.trace()]
        let context = context()
        manager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        deepLink = DeepLinkModule(context: context,
                                  moduleConfiguration: [:])
    }

    func updateSettings(_ builder: DeepLinkSettingsBuilder) {
        let configuration = builder.build()
            .getDataDictionary(key: "configuration")?.toDataObject() ?? [:]
        _ = deepLink.updateConfiguration(configuration)
    }
}
