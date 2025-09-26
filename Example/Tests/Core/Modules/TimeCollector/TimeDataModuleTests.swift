@testable import TealiumSwift
import XCTest

final class TimeDataModuleTests: XCTestCase {
    let firstOfJanuary2000: Int64 = 946_684_800_000
    let firstOfJuly2025: Int64 = 1_751_371_200_000
    let timeCollector: TimeDataModule! = TimeDataModule(context: mockContext,
                                                        moduleConfiguration: [:])
    var dispatch = Dispatch(name: "time")
    lazy var dispatchContext = DispatchContext(source: .application,
                                               initialData: dispatch.payload)

    // MARK: - Initialization Tests
    func test_initialization_is_successful_when_time_collector_is_created() {
        XCTAssertNotNil(timeCollector, "TimeDataModule should not be nil after initialization.")
        XCTAssertEqual(timeCollector.id, "TimeData", "TimeDataModule id should be 'Time'.")
        XCTAssertTrue(TimeDataModule.canBeDisabled, "TimeDataModule should be able to be disabled.")
    }

    // MARK: - Data Collection Tests
    func test_data_keys_exist_are_valid_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssertNotNil(data["tealium_timestamp_utc"], "Timestamp should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_local"], "Local timestamp should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_local_with_offset"], "Local timestamp with offset should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_offset"], "Timestamp offset should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_timezone"], "Timestamp timezone should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_epoch"], "Unix timestamp should not be nil.")
        XCTAssertNotNil(data["tealium_timestamp_epoch_milliseconds"],
                        "Unix timestamp in milliseconds should not be nil.")
    }

    func test_timestamp_formats_are_correct_when_collected() {
        dispatch = Dispatch(payload: [TealiumDataKey.event: "event"],
                            id: "someId",
                            timestamp: firstOfJanuary2000)
        let data = timeCollector.collect(dispatchContext).asDictionary()
        let date = Date(unixMilliseconds: firstOfJanuary2000)
        XCTAssertEqual(data, [
            "tealium_timestamp_utc": "2000-01-01T00:00:00Z",
            "tealium_timestamp_local": Date.Formatter.iso8601Local.string(from: date),
            "tealium_timestamp_local_with_offset": Date.Formatter.iso8601LocalWithOffset.string(from: date),
            "tealium_timestamp_offset": Float(TimeZone.current.secondsFromGMT()) / 3600, // e.g. 1, -2, 1.5, -2.75
            "tealium_timestamp_epoch_milliseconds": firstOfJanuary2000,
            "tealium_timestamp_epoch": firstOfJanuary2000 / 1000,
            "tealium_timestamp_timezone": TimeZone.current.identifier // e.g. Europe/Dublin
        ])
    }

    func test_timestamp_values_match_expected_values_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        guard let timestamp = dispatchContext.initialData
            .get(key: TealiumDataKey.timestampUnixMilliseconds, as: Int64.self) else {
            XCTFail("Missing Timestamp")
            return
        }
        let expectedUnix = timestamp / 1000
        XCTAssertEqual(
            data["tealium_timestamp_epoch"] as? Int64,
            expectedUnix,
            "Unix timestamp should match the dispatch timestamp in seconds."
        )
        XCTAssertEqual(
            data["tealium_timestamp_epoch_milliseconds"] as? Int64,
            timestamp,
            "Unix timestamp in milliseconds should match the dispatch timestamp in milliseconds."
        )
    }

    func test_timezone_offset_matches_device_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        let timezoneOffset = data["tealium_timestamp_offset"] as? Float
        XCTAssertNotNil(timezoneOffset, "Timezone offset should not be nil.")
        let expectedOffset = TimeZone.current.secondsFromGMT() / 3600
        XCTAssertEqual(
            timezoneOffset,
            Float(expectedOffset),
            "Timezone offset should match the device's timezone offset."
        )
    }

    func test_data_structure_is_correct_when_collected() {
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssert(data["tealium_timestamp_utc"] is String, "Timestamp should be of type String.")
        XCTAssert(data["tealium_timestamp_local"] is String, "Local timestamp should be of type String.")
        XCTAssert(data["tealium_timestamp_local_with_offset"] is String, "Local timestamp with offset should be of type String.")
        XCTAssert(data["tealium_timestamp_offset"] is Float, "Timestamp offset should be of type Float.")
        XCTAssert(data["tealium_timestamp_timezone"] is String, "Timestamp timezone should be of type String.")
        XCTAssert(data["tealium_timestamp_epoch"] is Int64, "Unix timestamp should be of type Int64.")
        XCTAssert(data["tealium_timestamp_epoch_milliseconds"] is Int64, "Unix timestamp in milliseconds should be of type Int64.")
    }

    func test_iso8601_string_is_valid_when_event_is_dispatched() {
        dispatch = Dispatch(name: "test_event", type: .event)
        let data = timeCollector.collect(dispatchContext).asDictionary()

        XCTAssertNotNil(data["tealium_timestamp_utc"], "Timestamp should not be nil.")
        guard let timestamp = dispatchContext.initialData
            .get(key: TealiumDataKey.timestampUnixMilliseconds, as: Int64.self) else {
            XCTFail("Missing Timestamp")
            return
        }
        XCTAssertEqual(
            data["tealium_timestamp_utc"] as? String,
            Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000).iso8601String,
            "ISO8601 timestamp should match."
        )
    }

    func test_local_date_minus_timezoneOffset_equals_gmt_date_summer() {
        dispatch = Dispatch(payload: [TealiumDataKey.event: "event"],
                            id: "someId",
                            timestamp: firstOfJuly2025)
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssertEqual(data["tealium_timestamp_epoch_milliseconds"] as? Int64, firstOfJuly2025)
        guard let localTimestamp = data["tealium_timestamp_local"] as? String,
              let gmtTimestamp = data["tealium_timestamp_utc"] as? String,
              let localDate = Date.Formatter.iso8601.date(from: localTimestamp),
              let gmtDate = Date.Formatter.iso8601.date(from: gmtTimestamp) else {
            XCTFail("Could not extract timestamps from \(data)")
            return
        }
        let offset = TimeZone.current.secondsFromGMT(for: Date(unixMilliseconds: firstOfJuly2025))
        XCTAssertEqual(localDate.unixTimeSeconds - Int64(offset),
                       gmtDate.unixTimeSeconds)
    }

    func test_local_date_minus_timezoneOffset_equals_gmt_date_winter() {
        dispatch = Dispatch(payload: [TealiumDataKey.event: "event"],
                            id: "someId",
                            timestamp: firstOfJanuary2000)
        let data = timeCollector.collect(dispatchContext).asDictionary()
        XCTAssertEqual(data["tealium_timestamp_epoch_milliseconds"] as? Int64, firstOfJanuary2000)
        guard let localTimestamp = data["tealium_timestamp_local"] as? String,
              let gmtTimestamp = data["tealium_timestamp_utc"] as? String,
              let localDate = Date.Formatter.iso8601.date(from: localTimestamp),
              let gmtDate = Date.Formatter.iso8601.date(from: gmtTimestamp) else {
            XCTFail("Could not extract timestamps from \(data)")
            return
        }

        let offset = TimeZone.current.secondsFromGMT(for: Date(unixMilliseconds: firstOfJanuary2000))
        XCTAssertEqual(localDate.unixTimeSeconds - Int64(offset),
                       gmtDate.unixTimeSeconds)
    }
}
