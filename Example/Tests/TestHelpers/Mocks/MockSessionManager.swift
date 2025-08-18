//
//  MockSessionManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class MockSessionManager: SessionManager {

    let databaseProvider: DatabaseProviderProtocol

    @ToAnyObservable(BasePublisher<Dispatch>())
    var onRegisterDispatch: Observable<Dispatch>
    init(databaseProvider: DatabaseProviderProtocol = MockDatabaseProvider()) {
        self.databaseProvider = databaseProvider
        let modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: modulesRepository)
        let dataStore: DataStore
        do {
            dataStore = try storeProvider.getModuleStore(name: "core")
        } catch {
            XCTFail("Failed to get module store: \(error)")
            // Provide a fallback or terminate; here we use fatalError to stop the test
            fatalError("Failed to get module store: \(error)")
        }
        super.init(
            debouncer: Debouncer(queue: .worker),
            dataStore: dataStore,
            moduleRepository: MockModulesRepository(),
            sessionTimeout: .constant(5.minutes),
            logger: nil)
    }

    override func registerDispatch(_ dispatch: inout Dispatch) {
        _onRegisterDispatch.publish(dispatch)
        super.registerDispatch(&dispatch)
    }
}
