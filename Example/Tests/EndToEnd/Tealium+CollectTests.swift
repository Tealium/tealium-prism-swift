//
//  Tealium+CollectTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumCollectTests: TealiumBaseTests {

    static func decodeBody(_ body: Data?, asserting: ([String: Any]) -> Void = { _ in }) {
        XCTAssertTrueOptional(body?.isGzipped, "Body should be gzipped")
        guard let unzippedBody = try? body?.gunzipped(),
        let deserializedBody = try? JSONSerialization.jsonObject(with: unzippedBody) as? [String: Any] else {
            XCTFail("Can't deserialize body")
            return
        }
        asserting(deserializedBody)
    }

    override func setUp() {
        super.setUp()
        config.networkClient = client
    }

    func test_collect_sends_basic_event() {
        config.addModule(Modules.collect())
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            XCTAssertEqual(request.url?.absoluteString, "https://collect.tealiumiq.com/event")
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                XCTAssertEqual(body, [
                    "enabled_modules": [
                        "Collect",
                        "DataLayer",
                        "TealiumData"
                    ],
                    "enabled_modules_versions": [
                        TealiumConstants.libraryVersion,
                        TealiumConstants.libraryVersion,
                        TealiumConstants.libraryVersion
                    ],
                    "tealium_account": "mockAccount",
                    "tealium_profile": "mockProfile",
                    "tealium_environment": "mockEnv",
                    "tealium_event": "Event",
                    "tealium_event_type": "event",
                    "tealium_library_name": "swift",
                    "tealium_library_version": TealiumConstants.libraryVersion,
                    "tealium_random": body["tealium_random"],
                    "tealium_timestamp_epoch_milliseconds": body["tealium_timestamp_epoch_milliseconds"],
                    "tealium_visitor_id": body["tealium_visitor_id"]
                ])
            }
        }
        let teal = createTealium()
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_collect_sends_event_with_collected_data() {
        config.addModule(Modules.collect())
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                XCTAssertEqual(body["data_layer_key"] as? String, "data_layer_value")
            }
        }
        let teal = createTealium()
        teal.dataLayer.put(key: "data_layer_key", value: "data_layer_value")
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_collect_sends_event_to_custom_endpoint() {
        let customUrl = "https://www.tealium.com"
        config.addModule(Modules.collect(forcingSettings: { builder in
            builder.setUrl(customUrl)
        }))
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            httpRequestSent.fulfill()
            XCTAssertEqual(request.url?.absoluteString, customUrl)
            Self.decodeBody(request.httpBody)
        }
        let teal = createTealium()
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_collect_sends_multiple_events_in_a_batch() {
        config.addModule(Modules.collect())
        let barrierFactory = MockBarrierFactory(defaultScope: [.all])
        config.addBarrier(barrierFactory)
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            XCTAssertEqual(request.url?.absoluteString, "https://collect.tealiumiq.com/bulk-event")
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                let shared = body["shared"] as? [String: Any]
                XCTAssertEqual(shared, [
                    "tealium_account": "mockAccount",
                    "tealium_profile": "mockProfile",
                    "tealium_visitor_id": shared?["tealium_visitor_id"]
                ])
                let events = body["events"] as? [[String: Any]]
                XCTAssertEqual(events?.map { $0["tealium_event"] }, ["Event1", "Event2"])
            }
        }
        barrierFactory.barrier.setState(.closed)
        let teal = createTealium()
        teal.track("Event1")
        teal.track("Event2").subscribe { _ in
            barrierFactory.barrier.setState(.open)
        }
        waitForLongTimeout()
    }

    func test_collect_sends_mapped_event() {
        config.addModule(Modules.collect(forcingSettings: { enforcedSettings in
            enforcedSettings.setMappings([
                .keep("tealium_account"),
                .keep("tealium_profile"),
                .keep("tealium_visitor_id"),
                .from("tealium_event", to: "event_name")
            ])
        }))
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                XCTAssertEqual(body, [
                    "tealium_account": "mockAccount",
                    "tealium_profile": "mockProfile",
                    "tealium_visitor_id": body["tealium_visitor_id"],
                    "event_name": "Event"
                ])
            }
        }

        let teal = createTealium()
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_collect_sends_transformed_event() {
        config.addModule(Modules.collect())
        config.addModule(MockModuleFactory(module: MockTransformer(transformation: { _, dispatch, _ in
            Dispatch(payload: [
                "tealium_account": dispatch.payload.getDataItem(key: "tealium_account"),
                "tealium_profile": dispatch.payload.getDataItem(key: "tealium_profile"),
                "tealium_visitor_id": dispatch.payload.getDataItem(key: "tealium_visitor_id"),
                "tealium_event": dispatch.payload.getDataItem(key: "tealium_event"),
                "transformed_key": "transformed_value"
            ], id: dispatch.id, timestamp: 0)
        })))
        config.setTransformation(TransformationSettings(id: "transformation",
                                                        transformerId: MockTransformer.id,
                                                        scopes: [.allDispatchers]))
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                XCTAssertEqual(body, [
                    "tealium_account": "mockAccount",
                    "tealium_profile": "mockProfile",
                    "tealium_visitor_id": body["tealium_visitor_id"],
                    "tealium_event": "Event",
                    "tealium_timestamp_epoch_milliseconds": 0,
                    "transformed_key": "transformed_value"
                ])
            }
        }
        let teal = createTealium()
        teal.track("Event")
        waitForLongTimeout()
    }
}
