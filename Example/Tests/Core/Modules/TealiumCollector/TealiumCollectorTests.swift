//
//  TealiumCollectorTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumCollectorTests: XCTestCase {
    let modulesManager = ModulesManager(queue: TealiumQueue.main)
    let config = TealiumCollectorTests.getConfig(source: "mock_source")
    lazy var context = MockContext(modulesManager: modulesManager, config: config)
    lazy var collector = TealiumCollector(context: context, moduleConfiguration: [:])
    lazy var data = collector.collect(DispatchContext(source: .application, initialData: [:]))
    override func setUp() {
        modulesManager.updateSettings(context: context, settings: SDKSettings())
    }

    static func getConfig(source: String?) -> TealiumConfig {
        TealiumConfig(account: "mock_account",
                      profile: "mock_profile",
                      environment: "mock_env",
                      dataSource: source,
                      modules: [DefaultModuleFactory<MockDispatcher>()],
                      settingsFile: nil,
                      settingsUrl: nil)
    }

    func test_collect_returns_static_data() {
        XCTAssertEqual(data.get(key: "tealium_account"), "mock_account")
        XCTAssertEqual(data.get(key: "tealium_profile"), "mock_profile")
        XCTAssertEqual(data.get(key: "tealium_environment"), "mock_env")
        XCTAssertEqual(data.get(key: "tealium_datasource"), "mock_source")
        XCTAssertEqual(data.get(key: "tealium_library_name"), TealiumConstants.libraryName)
        XCTAssertEqual(data.get(key: "tealium_library_version"), TealiumConstants.libraryVersion)
    }

    func test_collect_doesnt_contain_source_when_nil() {
        let config = Self.getConfig(source: nil)
        context = MockContext(modulesManager: modulesManager, config: config)
        XCTAssertFalse(data.keys.contains("tealium_datasource"),
                       "tealium_datasource should not be present in the collected data")
    }

    func test_collect_returns_16_digit_random_number_as_string() {
        let random = data.get(key: "tealium_random", as: String.self)
        XCTAssertNotNil(random)
        XCTAssertEqual(random?.count, 16)
        XCTAssertNotNil(Int(random ?? ""))
    }

    func test_collect_returns_visitorId() {
        XCTAssertEqual(data.get(key: "tealium_visitor_id"), "visitorId")
    }

    func test_collect_returns_modules_names() {
        XCTAssertEqual(data.getArray(key: "enabled_modules"), ["MockDispatcher"])
    }

    func test_collect_returns_modules_versions() {
        XCTAssertEqual(data.getArray(key: "enabled_modules_versions"), ["1.0.0"])
    }
}
