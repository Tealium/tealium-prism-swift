//
//  Operators.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//

import Foundation

extension TealiumObservable {
    
    class TealiumSubscriptionWrapper: TealiumDisposableProtocol {
        var subscription: TealiumDisposableProtocol?
        public private(set) var isDisposed: Bool = false
        let queue: DispatchQueue
        init(queue: DispatchQueue) {
            self.queue = queue
        }
        func dispose() {
            queue.async { // We might want to add a check if we are already on that queue then don't dispatch
                self.subscription?.dispose()
            }
            isDisposed = true
        }
    }
    
    public func subscribeOn(_ queue: DispatchQueue) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let subscription = TealiumSubscriptionWrapper(queue: queue)
            queue.async { // We might want to add a check if we are already on that queue then don't dispatch
                subscription.subscription = self.subscribe(observer)
            }
            return subscription
        }
    }
    
    public func observeOn(_ queue: DispatchQueue) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                queue.async { // We might want to add a check if we are already on that queue then don't dispatch
                    observer(element)
                }
            }
        }
    }
    
    public func map<Result>(_ transform: @escaping (Element) -> Result) -> TealiumObservable<Result> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                observer(transform(element))
            }
        }
    }
    
    public func compactMap<Result>(_ transform: @escaping (Element) -> Result?) -> TealiumObservable<Result> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                if let transformed = transform(element) {
                    observer(transformed)
                }
            }
        }
    }
    
    public func filter(_ isIncluded: @escaping (Element) -> Bool) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                if isIncluded(element) {
                    observer(element)
                }
            }
        }
    }
    
    public func flatMap<Result>(_ selector: @escaping (Element) -> TealiumObservable<Result>) -> TealiumObservable<Result> {
        return TealiumObservableCreate<Result> { observer in
            let container = TealiumDisposeContainer()
            _ = self.subscribe { element in
                 selector(element)
                    .subscribe(observer)
                    .toDisposeContainer(container)
            }
            return container
        }
    }
}
