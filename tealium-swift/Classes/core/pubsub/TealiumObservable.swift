//
//  TealiumObservableImpl.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//

import Foundation

/// Abstract Class
public class TealiumObservable<Element>: TealiumObservableProtocol {

    fileprivate init() {
    }
    
    public func subscribe(_ observer: @escaping Observer) -> TealiumDisposableProtocol {
        assertionFailure("Subscribe on abstract class should never be called")
        return TealiumSubscription { }
    }
    
    fileprivate func publish(_ element: Element) {
        assertionFailure("Publish on abstract class should never be called")
    }
}


fileprivate class TealiumObservableImpl<Element>: TealiumObservable<Element> {
    private var count = 0
    fileprivate var observers = [String: Observer]()
    fileprivate var orderedKeys = [String]()
    fileprivate override init() {}

    @discardableResult
    override func subscribe(_ observer: @escaping Observer) -> TealiumDisposableProtocol {
        count += 1
        let key = String(count)
        observers[key] = observer
        orderedKeys.append(key)
        return TealiumSubscription { [weak self] in
            self?.unsubscribe(key: key)
        }
    }
    
    private func unsubscribe(key: String) {
        if observers[key] != nil {
            observers.removeValue(forKey: key)
            orderedKeys.removeAll { $0 == key }
        }
    }

    fileprivate override func publish(_ element: Element) {
        let orderedKeys = self.orderedKeys
        for key in orderedKeys {
            if let observer = observers[key] {
                observer(element)
            }
        }
    }

    func asObservable() -> TealiumObservable<Element> {
        self
    }
}

public class TealiumObservableCreate<Element>: TealiumObservable<Element> {
    public typealias SubscribeHandler = (@escaping Observer) -> TealiumDisposableProtocol
    let subscribeHandler: SubscribeHandler
    public init(_ subscribe: @escaping SubscribeHandler) {
        self.subscribeHandler = subscribe
    }
    override public func subscribe(_ observer: @escaping Observer) -> TealiumDisposableProtocol {
        subscribeHandler(observer)
    }
    
    public class func Callback(callback: @escaping (@escaping Observer) -> Void) -> TealiumObservableCreate<Element> {
        TealiumObservableCreate { observer in
            var cancelled = false
            callback { res in
                if !cancelled {
                    observer(res)
                }
            }
            return TealiumSubscription {
                cancelled = true
            }
        }
    }
}


public class TealiumPublisher<Element>: TealiumPublisherProtocol {
    fileprivate let observable: TealiumObservableImpl<Element>

    public init() {
        self.observable = TealiumObservableImpl<Element>()
    }
    
    public func publish(_ element: Element) {
        observable.publish(element)
    }
    
    public func asObservable() -> TealiumObservable<Element> {
        observable
    }
}

public extension TealiumPublisher where Element == Void {
    func publish() {
        self.publish(())
    }
}
