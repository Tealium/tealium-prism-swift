//
//  TealiumObservableProtocol.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//

import Foundation

public protocol TealiumObservableConvertibleProtocol {
    associatedtype Element

    func asObservable() -> TealiumObservable<Element>
}

public protocol TealiumObservableProtocol: TealiumObservableConvertibleProtocol {
    typealias Observer = (Element) -> Void

    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> any TealiumDisposableProtocol
}

extension TealiumObservableProtocol {
    public func asObservable() -> TealiumObservable<Element> {
        TealiumObservableCreate<Element> { observer in self.subscribe(observer) }
    }
}

public extension TealiumObservableProtocol {
    @discardableResult
    func subscribeOnce(_ observer: @escaping Observer) -> TealiumDisposableProtocol {
        var escapingSubscription: TealiumDisposableProtocol?
        var shouldDispose = false
        let subscription = subscribe({ element in
            guard !shouldDispose else {
                return
            }
            defer {
                observer(element)
            }
            if let sub = escapingSubscription {
                sub.dispose()
            } else {
                shouldDispose = true
            }
        })
        escapingSubscription = subscription
        if shouldDispose {
            subscription.dispose()
        }
        return subscription
    }
}
