//
//  RetryableErrorInterceptorTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class RetryableErrorInterceptorTests: XCTestCase {
    let transientDelay = 0.5
    let throttlingDelay = 3.0

    func interceptor(maxAttempts: Int?,
                     maxDelay: TimeInterval = 20,
                     longRetryAfter: RetryableErrorInterceptor.LongRetryAfter = .giveUp,
                     now: @escaping () -> Date = { Date() }) -> RetryableErrorInterceptor {
        RetryableErrorInterceptor(maxAttempts: maxAttempts,
                                  maxDelay: maxDelay,
                                  transientBackoff: .fixed(transientDelay),
                                  throttlingBackoff: .fixed(throttlingDelay),
                                  longRetryAfter: longRetryAfter,
                                  now: now)
    }

    /// A fixed reference date, and its IMF-fixdate representation.
    let retryDate = Date(timeIntervalSince1970: 1_792_567_680) // Wed, 21 Oct 2026 07:28:00 GMT
    let retryDateHeader = "Wed, 21 Oct 2026 07:28:00 GMT"

    func httpDate(_ secondsFromRetryDate: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: retryDate.addingTimeInterval(secondsFromRetryDate))
    }

    func failure(status: Int, headers: [String: String]? = nil) throws -> NetworkResult {
        .failure(NetworkError(type: .non200Status(status, nil),
                              urlResponse: .mock(status: status, headers: headers)))
    }

    func shouldRetry(_ interceptor: RetryableErrorInterceptor, consecutiveRetryCount: Int = 0, with result: NetworkResult) -> RetryPolicy {
        interceptor.shouldRetry(URLRequest(), consecutiveRetryCount: consecutiveRetryCount, with: result)
    }

    /// Samples the delay several times, asserting every sample is within `0...upperBound` and that they are not all equal.
    func assertRandomDelays(_ interceptor: RetryableErrorInterceptor,
                            consecutiveRetryCount: Int,
                            with result: NetworkResult,
                            upperBound: TimeInterval,
                            file: StaticString = #filePath,
                            line: UInt = #line) throws {
        let samples = try (0..<20).map { _ in
            try XCTUnwrap(delay(of: shouldRetry(interceptor, consecutiveRetryCount: consecutiveRetryCount, with: result)), file: file, line: line)
        }
        for sample in samples {
            XCTAssertTrue((0...upperBound).contains(sample), "Expected a delay in 0...\(upperBound), got \(sample)", file: file, line: line)
        }
        XCTAssertGreaterThan(Set(samples).count, 1, "Delays should be random, got \(samples)", file: file, line: line)
    }

    func test_success_is_not_retried() {
        let result = NetworkResult.success(.successful())
        XCTAssertEqual(shouldRetry(interceptor(maxAttempts: nil), with: result), .doNotRetry)
    }

    func test_non_retryable_status_is_not_retried() throws {
        XCTAssertEqual(shouldRetry(interceptor(maxAttempts: nil), with: try failure(status: 400)), .doNotRetry)
    }

    func test_cancelled_is_not_retried() {
        let result = NetworkResult.failure(NetworkError(type: .cancelled))
        XCTAssertEqual(shouldRetry(interceptor(maxAttempts: nil), with: result), .doNotRetry)
    }

    func test_non_retryable_url_error_is_not_retried() {
        let result = NetworkResult.failure(NetworkError(type: .urlError(URLError(.badURL))))
        XCTAssertEqual(shouldRetry(interceptor(maxAttempts: nil), with: result), .doNotRetry)
    }

    func test_nil_maxAttempts_retries_at_large_retryCount() throws {
        let policy = shouldRetry(interceptor(maxAttempts: nil), consecutiveRetryCount: 10_000, with: try failure(status: 503))
        XCTAssertEqual(delay(of: policy), transientDelay)
    }

    func test_maxAttempts_3_retries_twice_then_stops() throws {
        let interceptor = interceptor(maxAttempts: 3)
        let result = try failure(status: 503)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, consecutiveRetryCount: 0, with: result)), transientDelay)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, consecutiveRetryCount: 1, with: result)), transientDelay)
        XCTAssertEqual(shouldRetry(interceptor, consecutiveRetryCount: 2, with: result), .doNotRetry)
        XCTAssertEqual(shouldRetry(interceptor, consecutiveRetryCount: 3, with: result), .doNotRetry)
    }

    func test_maxAttempts_1_never_retries() throws {
        let interceptor = interceptor(maxAttempts: 1)
        XCTAssertEqual(shouldRetry(interceptor, consecutiveRetryCount: 0, with: try failure(status: 503)), .doNotRetry)
        XCTAssertEqual(shouldRetry(interceptor, consecutiveRetryCount: 0, with: try failure(status: 429)), .doNotRetry)
    }

    func test_429_uses_throttling_backoff() throws {
        let policy = shouldRetry(interceptor(maxAttempts: nil), with: try failure(status: 429))
        XCTAssertEqual(delay(of: policy), throttlingDelay)
    }

    func test_503_uses_transient_backoff() throws {
        let policy = shouldRetry(interceptor(maxAttempts: nil), with: try failure(status: 503))
        XCTAssertEqual(delay(of: policy), transientDelay)
    }

    func test_timed_out_url_error_uses_transient_backoff() {
        let result = NetworkResult.failure(NetworkError(type: .urlError(URLError(.timedOut))))
        XCTAssertEqual(delay(of: shouldRetry(interceptor(maxAttempts: nil), with: result)), transientDelay)
    }

    func test_backoff_receives_consecutiveRetryCount_as_retry_count() throws {
        let interceptor = RetryableErrorInterceptor(maxAttempts: nil,
                                                    maxDelay: 20,
                                                    transientBackoff: .retryCount,
                                                    throttlingBackoff: .retryCount)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, consecutiveRetryCount: 0, with: try failure(status: 503))), 0)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, consecutiveRetryCount: 4, with: try failure(status: 429))), 4)
    }

    func test_retry_after_above_backoff_is_used() throws {
        let interceptor = interceptor(maxAttempts: nil)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: ["Retry-After": "7"]))), 7)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 429, headers: ["Retry-After": " 7 "]))), 7)
    }

    func test_retry_after_zero_uses_backoff() throws {
        let interceptor = interceptor(maxAttempts: nil)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: ["Retry-After": "0"]))), transientDelay)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 429, headers: ["Retry-After": "0"]))), throttlingDelay)
    }

    func test_retry_after_below_backoff_uses_backoff() throws {
        let interceptor = interceptor(maxAttempts: nil)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 429, headers: ["Retry-After": "2"]))), throttlingDelay)
    }

    func test_retry_after_equal_to_maxDelay_is_used() throws {
        let policy = shouldRetry(interceptor(maxAttempts: nil, maxDelay: 20),
                                 with: try failure(status: 503, headers: ["Retry-After": "20"]))
        XCTAssertEqual(delay(of: policy), 20)
    }

    func test_retry_after_above_maxDelay_gives_up_by_default() throws {
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 20)
        XCTAssertEqual(shouldRetry(interceptor, with: try failure(status: 503, headers: ["Retry-After": "21"])), .doNotRetry)
        XCTAssertEqual(shouldRetry(interceptor, with: try failure(status: 429, headers: ["Retry-After": "500"])), .doNotRetry)
    }

    func test_retry_after_above_maxDelay_is_waited_when_longRetryAfter_is_wait() throws {
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 20, longRetryAfter: .wait)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: ["Retry-After": "21"]))), 21)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 429, headers: ["Retry-After": "500"]))), 500)
    }

    func test_retry_after_is_ignored_when_maxAttempts_is_reached() throws {
        let policy = shouldRetry(interceptor(maxAttempts: 2),
                                 consecutiveRetryCount: 1,
                                 with: try failure(status: 503, headers: ["Retry-After": "7"]))
        XCTAssertEqual(policy, .doNotRetry)
    }

    func test_retry_after_http_date_is_measured_against_the_date_header() throws {
        let headers = ["Retry-After": retryDateHeader, "Date": httpDate(-30)]
        let policy = shouldRetry(interceptor(maxAttempts: nil, maxDelay: 100), with: try failure(status: 503, headers: headers))
        XCTAssertEqual(delay(of: policy), 30)
    }

    func test_retry_after_http_date_without_date_header_is_measured_against_now() throws {
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 100, now: { self.retryDate.addingTimeInterval(-12) })
        let policy = shouldRetry(interceptor, with: try failure(status: 503, headers: ["Retry-After": retryDateHeader]))
        XCTAssertEqual(delay(of: policy), 12)
    }

    func test_retry_after_http_date_prefers_the_date_header_over_a_skewed_device_clock() throws {
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 100, now: { self.retryDate.addingTimeInterval(-5 * 3600) })
        let headers = ["Retry-After": retryDateHeader, "Date": httpDate(-30)]
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: headers))), 30)
    }

    func test_retry_after_http_date_with_invalid_date_header_uses_now() throws {
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 100, now: { self.retryDate.addingTimeInterval(-12) })
        let headers = ["Retry-After": retryDateHeader, "Date": "not a date"]
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: headers))), 12)
    }

    func test_retry_after_http_date_in_the_past_uses_backoff() throws {
        let interceptor = interceptor(maxAttempts: nil, now: { self.retryDate.addingTimeInterval(60) })
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: ["Retry-After": retryDateHeader]))),
                       transientDelay)
        let headers = ["Retry-After": retryDateHeader, "Date": httpDate(60)]
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 429, headers: headers))), throttlingDelay)
    }

    func test_retry_after_http_date_below_backoff_uses_backoff() throws {
        let headers = ["Retry-After": retryDateHeader, "Date": httpDate(-2)]
        let policy = shouldRetry(interceptor(maxAttempts: nil), with: try failure(status: 429, headers: headers))
        XCTAssertEqual(delay(of: policy), throttlingDelay)
    }

    func test_retry_after_http_date_above_maxDelay_gives_up_by_default() throws {
        let headers = ["Retry-After": retryDateHeader, "Date": httpDate(-21)]
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 20)
        XCTAssertEqual(shouldRetry(interceptor, with: try failure(status: 503, headers: headers)), .doNotRetry)
    }

    func test_retry_after_http_date_above_maxDelay_is_waited_when_longRetryAfter_is_wait() throws {
        let headers = ["Retry-After": retryDateHeader, "Date": httpDate(-500)]
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 20, longRetryAfter: .wait)
        XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: headers))), 500)
    }

    func test_retry_after_obsolete_http_date_formats_fall_back_to_backoff() throws {
        let interceptor = interceptor(maxAttempts: nil, maxDelay: 100, now: { self.retryDate.addingTimeInterval(-30) })
        for value in ["Wednesday, 21-Oct-26 07:28:00 GMT", "Wed Oct 21 07:28:00 2026"] {
            let headers = ["Retry-After": value]
            XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: headers))), transientDelay, value)
            XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 429, headers: headers))), throttlingDelay, value)
        }
    }

    func test_garbage_retry_after_falls_back_to_backoff() throws {
        let interceptor = interceptor(maxAttempts: nil)
        for value in ["soon", "", "1.5", "Wed, 99 Foo 2026 07:28:00 GMT"] {
            let headers = ["Retry-After": value]
            XCTAssertEqual(delay(of: shouldRetry(interceptor, with: try failure(status: 503, headers: headers))), transientDelay, value)
        }
    }

    func test_negative_retry_after_falls_back_to_backoff() throws {
        let policy = shouldRetry(interceptor(maxAttempts: nil), with: try failure(status: 503, headers: ["Retry-After": "-5"]))
        XCTAssertEqual(delay(of: policy), transientDelay)
    }

    func test_public_initializer_uses_full_jitter_delays() throws {
        let interceptor = RetryableErrorInterceptor(maxAttempts: nil, transientBaseDelay: 0.1, throttlingBaseDelay: 1, maxDelay: 20)
        XCTAssertEqual(interceptor.maxDelay, 20)
        XCTAssertNil(interceptor.maxAttempts)
        for retryCount in 0..<10 {
            let transient = try XCTUnwrap(delay(of: shouldRetry(interceptor, consecutiveRetryCount: retryCount, with: try failure(status: 503))))
            XCTAssertGreaterThanOrEqual(transient, 0)
            XCTAssertLessThanOrEqual(transient, min(20, 0.1 * pow(2, Double(retryCount))))
            let throttling = try XCTUnwrap(delay(of: shouldRetry(interceptor, consecutiveRetryCount: retryCount, with: try failure(status: 429))))
            XCTAssertGreaterThanOrEqual(throttling, 0)
            XCTAssertLessThanOrEqual(throttling, min(20, pow(2, Double(retryCount))))
        }
        try assertRandomDelays(interceptor, consecutiveRetryCount: 3, with: try failure(status: 503), upperBound: 0.8)
        try assertRandomDelays(interceptor, consecutiveRetryCount: 3, with: try failure(status: 429), upperBound: 8)
    }

    func test_public_initializer_defaults() {
        let interceptor = RetryableErrorInterceptor()
        XCTAssertEqual(interceptor.maxAttempts, 3)
        XCTAssertEqual(interceptor.maxDelay, 20)
        XCTAssertEqual(interceptor.longRetryAfter, .giveUp)
    }

    func test_collect_interceptors_first_interceptor_uses_full_jitter_delays() throws {
        let interceptors = CollectModule.networkInterceptors(connectivityManager: MockConnectivityManager(queue: .worker))
        let interceptor = try XCTUnwrap(interceptors.first as? RetryableErrorInterceptor)
        try assertRandomDelays(interceptor, consecutiveRetryCount: 2, with: try failure(status: 503), upperBound: 0.1 * 4)
        try assertRandomDelays(interceptor, consecutiveRetryCount: 2, with: try failure(status: 429), upperBound: 1 * 4)
    }
}
