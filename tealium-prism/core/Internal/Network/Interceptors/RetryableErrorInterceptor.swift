//
//  RetryableErrorInterceptor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// Implementation of `RequestInterceptors.retryWithBackoff(maxAttempts:transientBaseDelay:throttlingBaseDelay:maxDelay:retryAfterAboveMaxDelay:)`,
/// see its documentation for the retry rules.
class RetryableErrorInterceptor: RequestInterceptor {
    let maxAttempts: Int?
    let maxDelay: TimeInterval
    let retryAfterAboveMaxDelay: RetryAfterAboveMaxDelay
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
     *    - maxAttempts: the maximum number of consecutive attempts, including the initial one. `nil` means there is no cap.
     *    - transientBaseDelay: the base delay, in seconds, for retryable failures other than HTTP 429.
     *    - throttlingBaseDelay: the base delay, in seconds, for HTTP 429 responses.
     *    - maxDelay: the longest backoff delay, in seconds. A `Retry-After` up to this long is waited as a minimum; a
     *    longer one is handled per `retryAfterAboveMaxDelay`.
     *    - retryAfterAboveMaxDelay: what to do when a `Retry-After` header asks for longer than `maxDelay`: `.giveUp`
     *    stops proposing a retry, so another interceptor may still retry, and `.wait` waits for the full header, with no
     *    upper bound.
     */
    convenience init(maxAttempts: Int? = 3,
                     transientBaseDelay: TimeInterval = 0.1,
                     throttlingBaseDelay: TimeInterval = 1,
                     maxDelay: TimeInterval = 20,
                     retryAfterAboveMaxDelay: RetryAfterAboveMaxDelay = .giveUp) {
        self.init(maxAttempts: maxAttempts,
                  maxDelay: maxDelay,
                  transientBackoff: .jitteredExponential(initialDelay: transientBaseDelay, maximum: maxDelay),
                  throttlingBackoff: .jitteredExponential(initialDelay: throttlingBaseDelay, maximum: maxDelay),
                  retryAfterAboveMaxDelay: retryAfterAboveMaxDelay)
    }

    init(maxAttempts: Int?,
         maxDelay: TimeInterval,
         transientBackoff: Backoff,
         throttlingBackoff: Backoff,
         retryAfterAboveMaxDelay: RetryAfterAboveMaxDelay = .giveUp,
         now: @escaping () -> Date = { Date() }) {
        self.maxAttempts = maxAttempts
        self.maxDelay = maxDelay
        self.retryAfterAboveMaxDelay = retryAfterAboveMaxDelay
        self.transientBackoff = transientBackoff
        self.throttlingBackoff = throttlingBackoff
        self.now = now
    }

    /// Ignored.
    func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult) { }

    func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy {
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
        if retryAfter > maxDelay, retryAfterAboveMaxDelay == .giveUp {
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
