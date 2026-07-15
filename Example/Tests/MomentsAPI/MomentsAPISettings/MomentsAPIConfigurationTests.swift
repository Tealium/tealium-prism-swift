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

    func test_momentsAPIRegion_rawValue_is_lowercase() {
        XCTAssertEqual(MomentsAPIRegion.germany.rawValue, "eu-central-1")
        XCTAssertEqual(MomentsAPIRegion.usEast.rawValue, "us-east-1")
        XCTAssertEqual(MomentsAPIRegion.sydney.rawValue, "ap-southeast-2")
        XCTAssertEqual(MomentsAPIRegion.oregon.rawValue, "us-west-2")
        XCTAssertEqual(MomentsAPIRegion.tokyo.rawValue, "ap-northeast-1")
        XCTAssertEqual(MomentsAPIRegion.hongKong.rawValue, "ap-east-1")
    }

    func test_momentsAPIRegion_init_is_case_insensitive() {
        XCTAssertEqual(MomentsAPIRegion(rawValue: "EU-CENTRAL-1"), .germany)
        XCTAssertEqual(MomentsAPIRegion(rawValue: "US-EAST-1"), .usEast)
        XCTAssertEqual(MomentsAPIRegion(rawValue: "AP-SOUTHEAST-2"), .sydney)
        XCTAssertEqual(MomentsAPIRegion(rawValue: "US-WEST-2"), .oregon)
        XCTAssertEqual(MomentsAPIRegion(rawValue: "AP-NORTHEAST-1"), .tokyo)
        XCTAssertEqual(MomentsAPIRegion(rawValue: "AP-EAST-1"), .hongKong)
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
