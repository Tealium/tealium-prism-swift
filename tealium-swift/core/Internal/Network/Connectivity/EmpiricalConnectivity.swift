//
//  EmpiricalConnectivity.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

protocol EmpiricalConnectivityProtocol {
    var onEmpiricalConnectionAvailable: Observable<Bool> { get }
    func connectionSuccess()
    func connectionFail()
}

/**
 * The class informs when the connection results to be empirically available or unavailable based on connection failed or successful detected elsewhere.
 *
 * The connection success/fail needs to be pushed from the outside, possibly by someone who is listening to networking events.
 */
class EmpiricalConnectivity: EmpiricalConnectivityProtocol {
    var numberOfFailedConsecutiveTimeouts = 0
    let debouncer: DebouncerProtocol
    let backoffPolocy: BackoffPolicy
    init(backoffPolocy: BackoffPolicy = ExponentialBackoff(), debouncer: DebouncerProtocol) {
        self.backoffPolocy = backoffPolocy
        self.debouncer = debouncer
    }

    /// An observable that emits `true` when connection is available and `false` otherwise. Starts with `true`.
    @ToAnyObservable<ReplaySubject<Bool>>(ReplaySubject<Bool>(initialValue: true))
    var onEmpiricalConnectionAvailable: Observable<Bool>

    /**
     * Call this method when an HTTP connection was successfully established.
     *
     * This method will set the empirical connection immediately to available as we just successfully made a connection to a server.
     *
     * - Note: the response doesn't have to be successful as long as we receive a response from a server,
     * the connection is still assumed to be available.
     *
     * - Warning: make sure that the request was not returned from a local cache, otherwise there's no guarantee that we have conneciton.
     */
    func connectionSuccess() {
        numberOfFailedConsecutiveTimeouts = 0
        debouncer.cancel()
        notify(assumeAvailable: true)
    }

    /**
     * Call this method when an HTTP connection was failed due to a client side connectivity issue.
     *
     * This method will set the empirical connection to be unavailable until a debounce time is passed.
     * Every call of this method will reset the debouncer and further delay the connection to result as available again.
     */
    func connectionFail() {
        notify(assumeAvailable: false)
        debouncer.debounce(time: timeoutInterval()) {
            self.numberOfFailedConsecutiveTimeouts += 1
            self.notify(assumeAvailable: true)
        }
    }

    func timeoutInterval() -> Double {
        backoffPolocy.backoff(forAttempt: numberOfFailedConsecutiveTimeouts + 1)
    }

    private func notify(assumeAvailable: Bool) {
        _onEmpiricalConnectionAvailable.publisher
            .publishIfChanged(assumeAvailable)
    }
}
