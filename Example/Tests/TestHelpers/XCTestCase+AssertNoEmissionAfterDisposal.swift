//
//  XCTestCase+AssertNoEmissionAfterDisposal.swift
//  tealium-prism
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

extension XCTestCase {
    /// Asserts that the observable produced by `applyOperator` does not emit
    /// a second event after the observer disposes on the first one.
    func assertNoEmissionAfterSideEffectDisposal<Element>(
        upstreamValues: [Int] = [1, 2],
        applyOperator: (NonDisposalCheckingObservable<Int>) -> Observable<Element>,
        assertions: @escaping (Element) -> Void = { _ in },
    ) {
        let disposable = Disposables.composite()
        let observerCalled = expectation(description: "Observer is called once")
        let observable = NonDisposalCheckingObservable<Int> { observer in
            DispatchQueue.main.async {
                for value in upstreamValues {
                    observer(value)
                }
            }
            return Disposables.composite()
        }
        applyOperator(observable)
            .subscribe { element in
                assertions(element)
                disposable.dispose()
                observerCalled.fulfill()
            }.addTo(disposable)
        waitForDefaultTimeout()
    }
}
