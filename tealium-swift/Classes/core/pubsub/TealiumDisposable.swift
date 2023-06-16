//
//  Disposable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumDisposableProtocol {
    var isDisposed: Bool { get }
    func dispose()
}

public extension TealiumDisposableProtocol {
    func toDisposeBag(_ disposeBag: TealiumDisposeBag) {
        disposeBag.add(self)
    }
    func toDisposeContainer(_ disposeContainer: TealiumDisposeContainer) {
        disposeContainer.add(self)
    }
}

public class TealiumSubscription: TealiumDisposableProtocol {
    fileprivate var unsubscribe: () -> Void
    public private(set) var isDisposed: Bool = false
    public init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }

    public func dispose() {
        unsubscribe()
        isDisposed = true
    }
}

public class TealiumDisposeContainer: TealiumDisposableProtocol {
    private var disposables = [TealiumDisposableProtocol]()
    public private(set) var isDisposed: Bool = false
    public init() {}

    public func add(_ disposable: TealiumDisposableProtocol) {
        disposables.append(disposable)
    }

    public func dispose() {
        let disposables = self.disposables
        self.disposables = []
        for disposable in disposables {
            disposable.dispose()
        }
        isDisposed = true
    }
}

public class TealiumDisposeBag: TealiumDisposableProtocol {
    let container = TealiumDisposeContainer()
    public var isDisposed: Bool {
        container.isDisposed
    }
    public init() {}
    
    public func add(_ disposable: TealiumDisposableProtocol) {
        container.add(disposable)
    }

    public func dispose() {
        container.dispose()
    }

    deinit {
        dispose()
    }
}
