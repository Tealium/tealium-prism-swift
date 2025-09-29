//
//  CollectModuleConfigurationTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

extension CollectModuleConfiguration {
    init?(configuration: DataObject?) {
        guard let configuration else { return nil }
        self.init(configuration: configuration, logger: nil)
    }
}

final class CollectModuleConfigurationTests: XCTestCase {
    let customUrl = "https://www.tealium.com/somePath?somekey=someValue"

    func test_overrideDomainURL_changes_domain_on_baseUrl() {
        let url = CollectModuleConfiguration.overrideDomainURL(configuration: [CollectModuleConfiguration.Keys.overrideDomain: "www.overriddenDomain.com"], baseURL: customUrl)
        XCTAssertEqual(url?.absoluteString, "https://www.overriddenDomain.com/somePath?somekey=someValue")
    }

    func test_getURL_returns_custom_url_when_provided_in_the_configuration() {
        let url = CollectModuleConfiguration.getURL(configuration: [CollectModuleConfiguration.Keys.url: customUrl])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_getURL_returns_default_url_when_not_provided_in_the_configuration() {
        let url = CollectModuleConfiguration.getURL(configuration: [:])
        XCTAssertEqual(url?.absoluteString, CollectModuleConfiguration.Defaults.url)
    }

    func test_getURL_overrides_domain_on_default_url() {
        let url = CollectModuleConfiguration.getURL(configuration: [CollectModuleConfiguration.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, "https://www.overriddenDomain.com/event")
    }

    func test_getURL_does_not_override_domain_on_custom_url() {
        let url = CollectModuleConfiguration.getURL(configuration: [CollectModuleConfiguration.Keys.url: customUrl, CollectModuleConfiguration.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_getBatchURL_returns_custom_batchUrl_when_provided_in_the_configuration() {
        let url = CollectModuleConfiguration.getBatchURL(configuration: [CollectModuleConfiguration.Keys.batchUrl: customUrl])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_getBatchURL_returns_default_batchUrl_when_not_provided_in_the_configuration() {
        let url = CollectModuleConfiguration.getBatchURL(configuration: [:])
        XCTAssertEqual(url?.absoluteString, CollectModuleConfiguration.Defaults.batchUrl)
    }

    func test_getBatchURL_overrides_domain_on_default_batchUrl() {
        let url = CollectModuleConfiguration.getBatchURL(configuration: [CollectModuleConfiguration.Keys.overrideDomain: "www.overriddenDomain.com"])
        XCTAssertEqual(url?.absoluteString, "https://www.overriddenDomain.com/bulk-event")
    }

    func test_getBatchURL_does_not_override_domain_on_custom_batchUrl() {
        let url = CollectModuleConfiguration.getBatchURL(configuration: [
            CollectModuleConfiguration.Keys.batchUrl: customUrl,
            CollectModuleConfiguration.Keys.overrideDomain: "www.overriddenDomain.com"
        ])
        XCTAssertEqual(url?.absoluteString, customUrl)
    }

    func test_overrideProfile_is_set_on_init() {
        let configuration = CollectModuleConfiguration(configuration: [CollectModuleConfiguration.Keys.overrideProfile: "override"])
        XCTAssertEqual(configuration?.overrideProfile, "override")
    }

    func test_is_not_initialized_when_url_is_invalid() {
        XCTAssertNil(CollectModuleConfiguration(configuration: [CollectModuleConfiguration.Keys.url: ""]))
    }

    func test_is_not_initialized_when_batchUrl_is_invalid() {
        XCTAssertNil(CollectModuleConfiguration(configuration: [CollectModuleConfiguration.Keys.batchUrl: ""]))
    }

    func test_create_configuration_from_builder_sets_url_batchUrl_and_overrideProfile() {
        let builder = CollectSettingsBuilder()
            .setUrl("url")
            .setBatchUrl("batchUrl")
            .setOverrideProfile("overrideProfile")
        let moduleSettings = builder.build(withModuleType: Modules.Types.collect)
            .getConvertible(converter: ModuleSettings.converter)
        let configuration = CollectModuleConfiguration(configuration: moduleSettings?.configuration)
        XCTAssertEqual(configuration?.url, URL(string: "url"))
        XCTAssertEqual(configuration?.batchUrl, URL(string: "batchUrl"))
        XCTAssertEqual(configuration?.overrideProfile, "overrideProfile")
    }

    func test_create_configuration_from_builder_sets_overrideDomain() {
        let builder = CollectSettingsBuilder()
            .setOverrideDomain("overrideDomain")
        let moduleSettings = builder.build(withModuleType: Modules.Types.collect)
            .getConvertible(converter: ModuleSettings.converter)
        let configuration = CollectModuleConfiguration(configuration: moduleSettings?.configuration)
        XCTAssertEqual(configuration?.url, URL(string: "https://overrideDomain/event"))
        XCTAssertEqual(configuration?.batchUrl, URL(string: "https://overrideDomain/bulk-event"))
    }
}
