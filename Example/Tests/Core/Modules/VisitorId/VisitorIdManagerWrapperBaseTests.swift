//
//  VisitorIdManagerWrapperBaseTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 08/10/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class VisitorIdManagerWrapperBaseTests: XCTestCase {
    static let identityKey = "email"
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let manager = ModuleManager()
    lazy var onManager = ReplaySubject<Result<ModuleManager, TealiumError>>(.success(manager))
    lazy var config: TealiumConfig = mockConfig
    lazy var sharedContext = MockContext(moduleManager: manager,
                                         config: config,
                                         databaseProvider: dbProvider,
                                         queue: queue)
    lazy var wrapper = VisitorIdManagerWrapper(moduleProxy: ModuleProxy(queue: queue,
                                                                        onModuleManager: onManager.asObservable()))

    func settings(enabled: Bool) -> SDKSettings {
        SDKSettings(modules: [VisitorIdModule.moduleType: ModuleSettings(moduleType: VisitorIdModule.moduleType,
                                                                         enabled: enabled)])
    }

    override func setUp() {
        config.modules = [Modules.visitorId(forcingSettings: { $0.setVisitorIdentityKey(Self.identityKey) })]
    }

    /// Creates the `VisitorIdModule` by applying `config`'s settings.
    func createModule() {
        manager.updateSettings(context: sharedContext, settings: SDKSettings(config.getEnforcedSDKSettings()))
    }
}
