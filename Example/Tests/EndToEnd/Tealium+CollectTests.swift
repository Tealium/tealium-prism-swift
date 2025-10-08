//
//  Tealium+CollectTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
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

    func test_collect_sends_basic_event() {
        config.addModule(Modules.collect(forcingSettings: { $0.setOrder(1) }))
        config.addModule(Modules.dataLayer(forcingSettings: { $0.setOrder(2) }))
        config.addModule(Modules.tealiumData(forcingSettings: { $0.setOrder(3) }))
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(request.url?.absoluteString, "https://collect.tealiumiq.com/event")
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                XCTAssertEqual(body, [
                    "_dc_ttl_": 5.minutes.inMilliseconds(),
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
                    "is_new_session": true,
                    "tealium_account": "mockAccount",
                    "tealium_profile": "mockProfile",
                    "tealium_environment": "mockEnv",
                    "tealium_event": "Event",
                    "tealium_event_type": "event",
                    "tealium_library_name": "prism-swift",
                    "tealium_library_version": TealiumConstants.libraryVersion,
                    "tealium_random": body["tealium_random"],
                    "tealium_session_id": body["tealium_session_id"],
                    "tealium_timestamp_epoch_milliseconds": body["tealium_timestamp_epoch_milliseconds"],
                    "tealium_visitor_id": body["tealium_visitor_id"]
                ])
            }
        }
        let teal = createTealium()
        teal.track("Event")
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
    }

    func test_collect_sends_event_with_collected_data() {
        config.addModule(Modules.collect())
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                XCTAssertEqual(body["data_layer_key"] as? String, "data_layer_value")
            }
        }
        let teal = createTealium()
        teal.dataLayer.put(key: "data_layer_key", value: "data_layer_value")
        teal.track("Event")
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
    }

    func test_collect_sends_event_to_custom_endpoint() {
        let customUrl = "https://www.tealium.com"
        config.addModule(Modules.collect(forcingSettings: { builder in
            builder.setUrl(customUrl)
        }))
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            httpRequestSent.fulfill()
            XCTAssertEqual(request.url?.absoluteString, customUrl)
            Self.decodeBody(request.httpBody)
        }
        let teal = createTealium()
        teal.track("Event")
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
    }

    func test_collect_sends_multiple_events_in_a_batch() {
        config.addModule(Modules.collect())
        let barrierFactory = MockBarrierFactory(defaultScope: [.all])
        config.addBarrier(barrierFactory)
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(request.url?.absoluteString, "https://collect.tealiumiq.com/bulk-event")
            httpRequestSent.fulfill()
            Self.decodeBody(request.httpBody) { body in
                let shared = body["shared"] as? [String: Any]
                XCTAssertEqual(shared, [
                    "tealium_account": "mockAccount",
                    "tealium_profile": "mockProfile",
                    "tealium_visitor_id": shared?["tealium_visitor_id"]
                ])
                guard let events = body["events"] as? [[String: Any]] else {
                    XCTFail("Events not found")
                    return
                }
                XCTAssertEqual(events.map { $0["tealium_event"] }, ["Event1", "Event2"])
                XCTAssertTrueOptional(events[0]["is_new_session"] as? Bool)
                XCTAssertNil(events[1]["is_new_session"])
                XCTAssertNotNil(events[0]["tealium_session_id"])
                XCTAssertEqual(events[0]["tealium_session_id"] as? Int64,
                               events[1]["tealium_session_id"] as? Int64)
                XCTAssertEqual(events[0]["_dc_ttl_"] as? Int64, 5.minutes.inMilliseconds())
                XCTAssertEqual(events[1]["_dc_ttl_"] as? Int64, 5.minutes.inMilliseconds())
            }
        }
        barrierFactory.barrier.setState(.closed)
        let teal = createTealium()
        teal.track("Event1")
        teal.track("Event2").subscribe { _ in
            barrierFactory.barrier.setState(.open)
        }
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
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
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
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
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
    }

    func test_collect_sends_transformed_event() {
        config.addModule(Modules.collect())
        config.addModule(StubModuleFactory(module: MockTransformer(transformation: { _, dispatch, _ in
            Dispatch(payload: [
                "tealium_account": dispatch.payload.getDataItem(key: "tealium_account"),
                "tealium_profile": dispatch.payload.getDataItem(key: "tealium_profile"),
                "tealium_visitor_id": dispatch.payload.getDataItem(key: "tealium_visitor_id"),
                "tealium_event": dispatch.payload.getDataItem(key: "tealium_event"),
                "transformed_key": "transformed_value"
            ], id: dispatch.id, timestamp: 0)
        })))
        config.setTransformation(TransformationSettings(id: "transformation",
                                                        transformerId: MockTransformer.moduleType,
                                                        scopes: [.allDispatchers]))
        let httpRequestSent = expectation(description: "Http Request is sent")
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
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
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
    }

    func test_collect_sends_events_with_updated_session_id_when_it_expires() {
        config.addModule(Modules.collect())
        let firstHttpRequestSent = expectation(description: "First HTTP Request is sent")
        let secondHttpRequestSent = expectation(description: "Second HTTP Request is sent")
        var sessionIds = [Int64?]()
        client.requestDidSend = { request in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            Self.decodeBody(request.httpBody) { body in
                sessionIds.append(body["tealium_session_id"] as? Int64)
            }
            if sessionIds.count == 1 {
                firstHttpRequestSent.fulfill()
            } else {
                secondHttpRequestSent.fulfill()
                XCTAssertNotEqual(sessionIds[0], sessionIds[1])
            }
        }
        let tenMinutesAgo = 10.minutes.beforeNow().unixTimeMilliseconds
        var teal: Tealium? = createTealium()
        _ = teal?.proxy.executeTask { tealium in
            tealium.track(Dispatch(payload: ["tealium_event": "Event1"],
                                   id: "1",
                                   timestamp: tenMinutesAgo),
                          onTrackResult: nil)
        }
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, expectations: [firstHttpRequestSent], timeout: Self.longTimeout)
        // Make sure tealium deallocates before creating a new one, or it will use same implementation
        teal = nil
        teal = createTealium() // Next launch
        teal?.track("Event2")
        waitForDispatchQueueToBeEmpty()
        waitOnQueue(queue: queue, expectations: [secondHttpRequestSent], timeout: Self.longTimeout)
    }

    func test_collect_initializes_multiple_times_with_different_ids() {
        config.addModule(Modules.collect(forcingSettings: { enforcedSettings in
            enforcedSettings
                .setUrl("Url1")
                .setOrder(0)
        }, { enforcedSettings in
            enforcedSettings
                .setModuleId("Collect2")
                .setUrl("Url2")
                .setOrder(1)
        }))
        let initializationCompleted = expectation(description: "Tealium initialization completed")
        let teal = createTealium()
        _ = teal.proxy.executeTask { impl in
            let modules = impl.modulesManager.modules.value.map { $0.id }
            XCTAssertTrue(modules.contains("Collect"))
            XCTAssertTrue(modules.contains("Collect2"))
            initializationCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_collect_does_not_initialize_multiple_times_if_using_same_moduleId() {
        config.addModule(Modules.collect(forcingSettings: { enforcedSettings in
            enforcedSettings
                .setUrl("Url1")
                .setOrder(0)
        }, { enforcedSettings in
            enforcedSettings
                .setUrl("Url2")
                .setOrder(1)
        }))
        let initializationCompleted = expectation(description: "Tealium initialization completed")
        let teal = createTealium()
        _ = teal.proxy.executeTask { impl in
            let modules = impl.modulesManager.modules.value.map { $0.id }
            for module in modules where module == "Collect" {
                initializationCompleted.fulfill()
            }
        }
        waitForDefaultTimeout()
    }
}
