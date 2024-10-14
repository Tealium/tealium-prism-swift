//
//  CollectSettingsTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

extension CollectSettings {
    init?(moduleSettings: DataObject) {
        self.init(moduleSettings: moduleSettings, logger: nil)
    }
}

final class CollectSettingsTests: XCTestCase {
    typealias Settings = CollectSettings
    let customUrl = "https://www.tealium.com/somePath?somekey=someValue"

    func test_overrideDomainURL_changes_domain_on_baseUrl() {
        let url = Settings.overrideDomainURL(moduleSettings: [Settings.Keys.overrideDomain: "www.overriddenDomain.com"], baseURL: customUrl)
        XCTAssertEqual(url?.absoluteString, "https://www.overriddenDomain.com/somePath?somekey=someValue")
    }

    func test_getURL_returns_custom_url_when_provided_in_the_settings() {
        let url = Settings.getURL(moduleSettings: [Settings.Keys.url: customUrl])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_getURL_returns_default_url_when_not_provided_in_the_settings() {
        let url = Settings.getURL(moduleSettings: [:])
        XCTAssertEqual(url?.absoluteString, Settings.Defaults.url)
    }

    func test_getURL_overrides_domain_on_default_url() {
        let url = Settings.getURL(moduleSettings: [Settings.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, "https://www.overriddenDomain.com/event")
    }

    func test_getURL_does_not_override_domain_on_custom_url() {
        let url = Settings.getURL(moduleSettings: [Settings.Keys.url: customUrl, Settings.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_getBatchURL_returns_custom_batchUrl_when_provided_in_the_settings() {
        let url = Settings.getBatchURL(moduleSettings: [Settings.Keys.batchUrl: customUrl])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_getBatchURL_returns_default_batchUrl_when_not_provided_in_the_settings() {
        let url = Settings.getBatchURL(moduleSettings: [:])
        XCTAssertEqual(url?.absoluteString, Settings.Defaults.batchUrl)
    }

    func test_getBatchURL_overrides_domain_on_default_batchUrl() {
        let url = Settings.getBatchURL(moduleSettings: [Settings.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, "https://www.overriddenDomain.com/bulk-event")
    }

    func test_getBatchURL_does_not_override_domain_on_custom_batchUrl() {
        let url = Settings.getBatchURL(moduleSettings: [Settings.Keys.batchUrl: customUrl, Settings.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_overrideProfile_is_set_on_init() {
        let settings = Settings(moduleSettings: [Settings.Keys.overrideProfile: "override"])
        XCTAssertEqual(settings?.overrideProfile, "override")
    }

    func test_is_not_initialized_when_url_is_invalid() {
        XCTAssertNil(CollectSettings(moduleSettings: [CollectSettings.Keys.url: ""]))
    }

    func test_is_not_initialized_when_batchUrl_is_invalid() {
        XCTAssertNil(CollectSettings(moduleSettings: [CollectSettings.Keys.batchUrl: ""]))
    }

    func test_create_settings_from_builder_sets_url_batchUrl_and_overrideProfile() {
        let builder = CollectSettingsBuilder()
            .setUrl("url")
            .setBatchUrl("batchUrl")
            .setOverrideProfile("overrideProfile")
        let settings = CollectSettings(moduleSettings: builder.build())
        XCTAssertEqual(settings?.url, URL(string: "url"))
        XCTAssertEqual(settings?.batchUrl, URL(string: "batchUrl"))
        XCTAssertEqual(settings?.overrideProfile, "overrideProfile")
    }

    func test_create_settings_from_builder_sets_overrideDomain() {
        let builder = CollectSettingsBuilder()
            .setOverrideDomain("overrideDomain")
        let settings = CollectSettings(moduleSettings: builder.build())
        XCTAssertEqual(settings?.url, URL(string: "https://overrideDomain/event"))
        XCTAssertEqual(settings?.batchUrl, URL(string: "https://overrideDomain/bulk-event"))
    }
}
