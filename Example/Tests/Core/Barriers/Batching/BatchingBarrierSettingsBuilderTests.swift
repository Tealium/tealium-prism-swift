//
//  BatchingBarrierSettingsBuilderTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 09/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BatchingBarrierSettingsBuilderTests: XCTestCase {

    func test_setBatchSize_sets_batch_size() {
        let builder = BatchingBarrierSettingsBuilder()
        let result = builder.setBatchSize(5).build()

        let configuration = result.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: BatchingBarrierConfiguration.Keys.batchSize), 5)
    }

    func test_inheritance_from_base_builder_works() {
        let result = BatchingBarrierSettingsBuilder()
            .setScopes([.dispatcher(id: "test-dispatcher")])
            .setBatchSize(3)
            .build()

        XCTAssertEqual(result.getArray(key: BarrierSettings.Keys.scopes), ["test-dispatcher"])
        let configuration = result.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: BatchingBarrierConfiguration.Keys.batchSize), 3)
    }
}
