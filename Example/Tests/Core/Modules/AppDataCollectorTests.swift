//
//  AppDataCollectorTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 18/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class MockBundle: Bundle, @unchecked Sendable {
    private let mockInfoDictionary: [String: Any]

    init(infoDictionary: [String: Any]) {
        self.mockInfoDictionary = infoDictionary
        super.init()
    }

    override var infoDictionary: [String: Any]? {
        return mockInfoDictionary
    }

    override var bundleIdentifier: String? {
        return mockInfoDictionary["CFBundleIdentifier"] as? String
    }
}

final class AppDataCollectorTests: XCTestCase {
    var mockInfo = [
        "CFBundleName": "TestApp",
        "CFBundleIdentifier": "com.example.testapp",
        "CFBundleShortVersionString": "1.2.3",
        "CFBundleVersion": "100"
    ]
    var mockBundle: Bundle {
        MockBundle(infoDictionary: mockInfo)
    }
    let dispatchContext = DispatchContext(source: .application, initialData: [:])

    func test_collect_returns_expected_data() {
        let appData = AppDataCollector(bundle: mockBundle).collect(dispatchContext)
        XCTAssertEqual(appData.get(key: TealiumDataKey.appBuild), "100")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appName), "TestApp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appRDNS), "com.example.testapp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appVersion), "1.2.3")
    }

    func test_collect_returns_expected_data_when_some_values_are_absent() {
        mockInfo.removeValue(forKey: "CFBundleShortVersionString")
        mockInfo.removeValue(forKey: "CFBundleVersion")
        let appData = AppDataCollector(bundle: mockBundle).collect(dispatchContext)
        XCTAssertEqual(appData.get(key: TealiumDataKey.appBuild), NSNull())
        XCTAssertEqual(appData.get(key: TealiumDataKey.appName), "TestApp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appRDNS), "com.example.testapp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appVersion), NSNull())
    }
}
