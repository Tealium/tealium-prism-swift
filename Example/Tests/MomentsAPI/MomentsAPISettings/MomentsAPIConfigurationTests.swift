//
//  MomentsAPIConfigurationTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MomentsAPIConfigurationTests: XCTestCase {

    // MARK: - Required Region Tests

    func test_init_with_empty_configuration_returns_nil() {
        let configuration = MomentsAPIConfiguration(configuration: [:])

        XCTAssertNil(configuration, "Configuration should return nil when region is missing")
    }

    // MARK: - Region Tests

    func test_init_with_custom_region_creates_custom() {
        let customRegion = "custom-region-1"
        let configuration = MomentsAPIConfiguration(configuration: [
            "moments_api_region": customRegion
        ])

        XCTAssertNotNil(configuration, "Configuration should accept custom regions")
        guard case .custom(let value) = configuration?.region else {
            XCTFail("Expected custom region but got: \(String(describing: configuration?.region))")
            return
        }
        XCTAssertEqual(value, customRegion, "Custom region should match input value")
    }

    func test_init_with_all_valid_regions() {
        let predefinedRegions: [MomentsAPIRegion] = [.germany, .usEast, .sydney, .oregon, .tokyo, .hongKong]
        for region in predefinedRegions {
            let configuration = MomentsAPIConfiguration(configuration: [
                "moments_api_region": region.rawValue
            ])

            XCTAssertEqual(configuration?.region, region, "Failed for region: \(region.rawValue)")
        }
    }

    // MARK: - Referrer Tests

    func test_init_with_valid_referrer() {
        let referrer = "https://custom-referrer.com"
        let configuration = MomentsAPIConfiguration(configuration: [
            "moments_api_region": MomentsAPIRegion.AWSRegion.usEast1,
            "moments_api_referrer": referrer
        ])

        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration?.referrer, referrer)
    }

    func test_init_without_referrer_sets_nil() {
        let configuration = MomentsAPIConfiguration(configuration: [
            "moments_api_region": MomentsAPIRegion.AWSRegion.usEast1
        ])

        XCTAssertNotNil(configuration)
        XCTAssertNil(configuration?.referrer)
    }

    func test_init_with_empty_string_referrer() {
        let configuration = MomentsAPIConfiguration(configuration: [
            "moments_api_region": MomentsAPIRegion.AWSRegion.usEast1,
            "moments_api_referrer": ""
        ])

        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration?.referrer, "")
    }
}
