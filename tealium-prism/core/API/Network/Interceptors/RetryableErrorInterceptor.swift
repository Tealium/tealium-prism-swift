//
//  RetryableErrorInterceptor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `RequestInterceptor` that retries retryable failures with a full-jitter exponential backoff, and decides when to give up.
 *
 * - A failure is retryable when its `NetworkErrorType.isRetryable` is `true`, for example HTTP 429 and 503, or a lost connection.
 * - The `n`-th retry in a row proposed by this interceptor, counting from 0, waits a random delay between 0 and
 *   `min(maxDelay, base * 2^n)`. `base` is `throttlingBaseDelay` for HTTP 429 and `transientBaseDelay` otherwise.
 * - A `Retry-After` header is a minimum wait: the delay is the larger of the header and the backoff. The header can be a
 *   number of seconds or an HTTP date in the IMF-fixdate format, measured against the response's `Date` header when present
 *   so a skewed device clock doesn't matter. Other formats are ignored. A header above `maxDelay` makes the interceptor give
 *   up or wait for it in full, depending on `longRetryAfter`.
 * - `maxAttempts` counts consecutive attempts, including the one that just failed. The count, and with it the backoff,
 *   restarts when another interceptor proposed the last retry, for example after waiting for connectivity.
 *   To limit the total retries of a request, derive the client with a `maxRetryCount`.
 */
public class RetryableErrorInterceptor: RequestInterceptor {
    /// What to do when a `Retry-After` header asks for longer than `maxDelay`.
    public enum LongRetryAfter {
        /// Stop retrying: the request completes with the throttled response.
        case giveUp
        /// Wait as long as the server asked, even beyond `maxDelay`.
        case wait
    }

    let maxAttempts: Int?
    let maxDelay: TimeInterval
    let longRetryAfter: LongRetryAfter
    private let transientBackoff: Backoff
    private let throttlingBackoff: Backoff
    private let now: () -> Date

    private static let imfFixdateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter
    }()

    /**
     * Creates a `RetryableErrorInterceptor`.
     *
     * - Parameters:
     *    - maxAttempts: the maximum number of consecutive attempts. `nil` means there is no cap.
     *    - transientBaseDelay: the base delay, in seconds, for retryable failures other than HTTP 429.
     *    - throttlingBaseDelay: the base delay, in seconds, for HTTP 429 responses.
     *    - maxDelay: the maximum delay, in seconds.
     *    - longRetryAfter: what to do when a `Retry-After` header asks for longer than `maxDelay`.
     */
    public convenience init(maxAttempts: Int? = 3,
                            transientBaseDelay: TimeInterval = 0.1,
                            throttlingBaseDelay: TimeInterval = 1,
                            maxDelay: TimeInterval = 20,
                            longRetryAfter: LongRetryAfter = .giveUp) {
        self.init(maxAttempts: maxAttempts,
                  maxDelay: maxDelay,
                  transientBackoff: .jitteredExponential(initialDelay: transientBaseDelay, maximum: maxDelay),
                  throttlingBackoff: .jitteredExponential(initialDelay: throttlingBaseDelay, maximum: maxDelay),
                  longRetryAfter: longRetryAfter)
    }

    init(maxAttempts: Int?,
         maxDelay: TimeInterval,
         transientBackoff: Backoff,
         throttlingBackoff: Backoff,
         longRetryAfter: LongRetryAfter = .giveUp,
         now: @escaping () -> Date = { Date() }) {
        self.maxAttempts = maxAttempts
        self.maxDelay = maxDelay
        self.longRetryAfter = longRetryAfter
        self.transientBackoff = transientBackoff
        self.throttlingBackoff = throttlingBackoff
        self.now = now
    }

    /// Ignored.
    public func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult) { }

    public func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy {
        guard case let .failure(error) = response, error.isRetryable else {
            return .doNotRetry
        }
        if let maxAttempts, consecutiveRetryCount + 1 >= maxAttempts {
            return .doNotRetry
        }

        let selectedBackoff = if case .non200Status(429, _) = error.type {
            throttlingBackoff
        } else {
            transientBackoff
        }
        let backoffDelay = selectedBackoff.calculate(consecutiveRetryCount)
        guard let retryAfter = retryAfterDelay(error.urlResponse) else {
            return .afterDelay(backoffDelay)
        }
        if retryAfter > maxDelay, longRetryAfter == .giveUp {
            return .doNotRetry
        }
        return .afterDelay(max(retryAfter, backoffDelay))
    }

    /// Returns the delay requested by the `Retry-After` header, or `nil` when it's missing or in an unsupported format.
    private func retryAfterDelay(_ urlResponse: HTTPURLResponse?) -> TimeInterval? {
        guard let header = urlResponse?.value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        if let seconds = Int(header) {
            return seconds >= 0 ? TimeInterval(seconds) : nil
        }
        guard let retryAfterDate = Self.imfFixdateFormatter.date(from: header) else {
            return nil
        }
        let referenceDate = urlResponse?.value(forHTTPHeaderField: "Date")
            .flatMap { Self.imfFixdateFormatter.date(from: $0.trimmingCharacters(in: .whitespaces)) } ?? now()
        return max(0, retryAfterDate.timeIntervalSince(referenceDate))
    }
}
