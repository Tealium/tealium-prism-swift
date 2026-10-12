//
//  VisitorIdManagerWrapperOrderingTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 08/10/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// Tests that enqueue work on the wrapper before the `VisitorIdModule` exists, so they create it themselves.
final class VisitorIdManagerWrapperOrderingTests: VisitorIdManagerWrapperBaseTests {
    func test_regenerate_queued_before_module_creation_binds_identity_already_in_dataLayer() throws {
        try sharedContext.dataLayer.edit()
            .put(key: Self.identityKey, value: "identityValue", expiry: .forever)
            .commit()
        // `regenerate()` is hot: it subscribes to the module the moment it's called, before the
        // module exists. `ModuleManager.onReady` gates `observeModule`, so that subscription waits
        // until `createModule()` below makes the module ready; both go through the Tealium queue in
        // call order, so this regenerate is the one bound to the identity already seeded from the
        // data layer, not whatever lands after it.
        let regenerateResult = wrapper.regenerate()
        queue.ensureOnQueue { self.createModule() }

        var newId: String?
        let regenerateCompleted = expectation(description: "regenerate completes")
        regenerateResult.subscribe { result in
            XCTAssertResultIsSuccess(result) { id in newId = id }
            regenerateCompleted.fulfill()
        }
        waitOnQueue(queue: queue)

        guard let newId else {
            XCTFail("regenerate() did not complete")
            return
        }
        guard let hashedIdentity = "identityValue".sha256() else {
            XCTFail("Failed to hash identity")
            return
        }
        let visitorIdStore = try sharedContext.moduleStoreProvider.getModuleStore(name: Modules.Types.visitorId)
        let visitorStorage = VisitorStorage(storage: visitorIdStore)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentity)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentity), newId)
    }
}
