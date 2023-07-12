//
//  EmpiricalConnectivity.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/06/23.
//

import Foundation

protocol EmpiricalConnectivityProtocol {
    var onEmpiricalConnectionAvailable: TealiumObservable<Bool> { get }
    func connectionSuccess()
    func connectionFail()
}

class EmpiricalConnectivity: EmpiricalConnectivityProtocol {
    var numberOfFailedConsecutiveTimeouts = 0
    let debouncer: DebouncerProtocol
    let backoffPolocy: BackoffPolicy
    init(backoffPolocy: BackoffPolicy = ExponentialBackoff(), debouncer: DebouncerProtocol = Debouncer(queue: tealiumQueue)) {
        self.backoffPolocy = backoffPolocy
        self.debouncer = debouncer
    }
    
    @ToAnyObservable(TealiumReplaySubject<Bool>(initialValue: true))
    var onEmpiricalConnectionAvailable: TealiumObservable<Bool>
    
    func connectionSuccess() {
        numberOfFailedConsecutiveTimeouts = 0
        debouncer.cancel()
        notify(assumeAvailable: true)
    }
    
    func connectionFail() {
        notify(assumeAvailable: false)
        debouncer.debounce(time: timeoutInterval()) {
            self.numberOfFailedConsecutiveTimeouts += 1
            self.notify(assumeAvailable: true)
        }
    }
    
    func timeoutInterval() -> Double {
        backoffPolocy.backoff(forAttempt: numberOfFailedConsecutiveTimeouts)
    }
    
    private func notify(assumeAvailable: Bool) {
        $onEmpiricalConnectionAvailable.publishIfChanged(assumeAvailable)
    }
}
