//
//  LifecycleModuleBaseTests.swift
//  LifecycleTests_iOS
//
//  Created by Enrico Zannini on 22/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class LifecycleModuleBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    @ToAnyObservable<ReplaySubject<ApplicationStatus>>(ReplaySubject<ApplicationStatus>())
    var applicationStatus: Observable<ApplicationStatus>
    let tracker = MockTracker()
    lazy var settings = LifecycleSettings(moduleSettings: [:])
    var module: LifecycleModule!
    let lifecycleDispatchContext = DispatchContext(source: .module(LifecycleModule.self),
                                                   initialData: TealiumDispatch(name: "lifecycle").eventData)
    let autoDisposer = AutomaticDisposer()

    override func setUpWithError() throws {
        let dataStoreProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
        let dataStore = try dataStoreProvider.getModuleStore(name: LifecycleModule.id)
        module = LifecycleModule(tracker: tracker,
                                 onApplicationStatus: applicationStatus,
                                 settings: settings,
                                 service: LifecycleService(lifecycleStorage: LifecycleStorage(dataStore: dataStore),
                                                           bundle: Bundle(for: type(of: self))),
                                 logger: nil)
    }

    func publishApplicationStatus(_ applicationStatus: ApplicationStatus) {
        _applicationStatus.publish(applicationStatus)
    }
}
