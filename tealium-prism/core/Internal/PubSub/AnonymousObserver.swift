//
//  AnonymousObserver.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

class AnonymousObserver<Element>: Observer {
    private var _onNext: ((Element) -> Void)?
    private var _onComplete: (() -> Void)?

    init(onNext: @escaping (Element) -> Void, onComplete: @escaping () -> Void) {
        self._onNext = onNext
        self._onComplete = onComplete
    }

    func onNext(_ element: Element) {
        _onNext?(element)
    }

    func onComplete() {
        let onComplete = _onComplete
        stop()
        onComplete?()
    }

    func stop() {
        _onNext = nil
        _onComplete = nil
    }
}
