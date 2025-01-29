@testable import TealiumSwift
import XCTest

final class TimeCollectorTests: XCTestCase {

    let timeCollector: TimeCollector! = TimeCollector(context: mockContext, moduleSettings: [:])
    let dispatchContext = DispatchContext(source: .application, initialData: TealiumDispatch(name: "time").eventData)

    // MARK: - Initialization Tests
    func test_initialization_is_successful_when_time_collector_is_created() {
        XCTAssertNotNil(timeCollector, "TimeCollector should not be nil after initialization.")
        XCTAssertEqual(TimeCollector.id, "Time", "TimeCollector id should be 'Time'.")
        XCTAssertTrue(TimeCollector.canBeDisabled, "TimeCollector should be able to be disabled.")
    }

    // MARK: - Data Collection Tests
    func test_data_keys_exist_are_valid_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssertNotNil(data["timestamp"], "Timestamp should not be nil.")
        XCTAssertNotNil(data["timestamp_local"], "Local timestamp should not be nil.")
        XCTAssertNotNil(data["timestamp_offset"], "Timestamp offset should not be nil.")
        XCTAssertNotNil(data["timestamp_unix"], "Unix timestamp should not be nil.")
        XCTAssertNotNil(data["timestamp_unix_milliseconds"], "Unix timestamp in milliseconds should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_epoch"], "Tealium timestamp epoch should not be nil.")
    }

    func test_timestamp_formats_are_correct_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssertEqual(
            (data["timestamp"] as? String)?.count,
            20,
            "Timestamp should be in ISO8601 format and have a length of 20 characters."
        )
    }

    func test_timestamp_values_match_expected_values_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        guard let timestamp = dispatchContext.initialData.getDataItem(key: TealiumDataKey.timestampUnixMilliseconds)?.get(as: Int64.self) else {
            XCTFail("Missing Timestamp")
            return
        }
        let expectedUnix = String(timestamp / 1000)
        XCTAssertEqual(
            data["timestamp_unix"] as? String,
            expectedUnix,
            "Unix timestamp should match the dispatch timestamp in seconds."
        )
        XCTAssertEqual(
            data["timestamp_unix_milliseconds"] as? String,
            String(timestamp),
            "Unix timestamp in milliseconds should match the dispatch timestamp in milliseconds."
        )
    }

    func test_timezone_offset_matches_device_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        let timezoneOffset = data["timestamp_offset"] as? String
        XCTAssertNotNil(timezoneOffset, "Timezone offset should not be nil.")
        let expectedOffset = TimeZone.current.secondsFromGMT() / 3600
        XCTAssertTrue(
            timezoneOffset?.contains("\(expectedOffset)") ?? false,
            "Timezone offset should match the device's timezone offset."
        )
    }

    func test_data_structure_is_correct_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssert(data["timestamp"] is String, "Timestamp should be of type String.")
        XCTAssert(data["timestamp_local"] is String, "Local timestamp should be of type String.")
        XCTAssert(data["timestamp_offset"] is String, "Timestamp offset should be of type String.")
        XCTAssert(data["timestamp_unix"] is String, "Unix timestamp should be of type String.")
        XCTAssert(data["timestamp_unix_milliseconds"] is String, "Unix timestamp in milliseconds should be of type String.")
        XCTAssert(data["tealium_timestamp_epoch"] is String, "Tealium timestamp epoch should be of type String.")
    }

    func test_iso8601_string_is_valid_when_event_is_dispatched() {
        let eventData = TealiumDispatch(name: "test_event", type: .event).eventData
        let dispatchContext = DispatchContext(source: .application, initialData: eventData)
        let data = timeCollector.collect(dispatchContext).asDictionary()

        XCTAssertNotNil(data["timestamp"], "Timestamp should not be nil.")
        guard let timestamp = dispatchContext.initialData.getDataItem(key: TealiumDataKey.timestampUnixMilliseconds)?.get(as: Int64.self) else {
            XCTFail("Missing Timestamp")
            return
        }
        XCTAssertEqual(
            data["timestamp"] as? String,
            Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000).iso8601String,
            "ISO8601 timestamp should match."
        )
    }
}
