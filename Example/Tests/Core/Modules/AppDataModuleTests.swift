//
//  AppDataModuleTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 18/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class AppDataModuleTests: XCTestCase {
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
        let appData = AppDataModule(bundle: mockBundle).collect(dispatchContext)
        XCTAssertEqual(appData.get(key: TealiumDataKey.appBuild), "100")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appName), "TestApp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appRDNS), "com.example.testapp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appVersion), "1.2.3")
    }

    func test_collect_returns_expected_data_when_some_values_are_absent() {
        mockInfo.removeValue(forKey: "CFBundleShortVersionString")
        mockInfo.removeValue(forKey: "CFBundleVersion")
        let appData = AppDataModule(bundle: mockBundle).collect(dispatchContext)
        XCTAssertEqual(appData.get(key: TealiumDataKey.appBuild), NSNull())
        XCTAssertEqual(appData.get(key: TealiumDataKey.appName), "TestApp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appRDNS), "com.example.testapp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appVersion), NSNull())
    }
}
