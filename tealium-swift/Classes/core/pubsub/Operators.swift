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
            self.subscribe { element in
                 selector(element)
                    .subscribe(observer)
                    .toDisposeContainer(container)
            }.toDisposeContainer(container)
            return container
        }
    }
    
    public func startWith(_ elements: Element...) -> TealiumObservable<Element> {
        return TealiumObservableCreate { observer in
            return self.subscribe { element in
                for startingElement in elements {
                    observer(startingElement)
                }
                observer(element)
            }
        }
    }
    
    public func merge(_ otherObservables: TealiumObservable<Element>...) -> TealiumObservable<Element> {
        return TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            self.subscribe(observer).toDisposeContainer(container)
            for observable in otherObservables {
                observable.subscribe(observer).toDisposeContainer(container)
            }
            return container
        }
    }
    
    public func first(where isIncluded: @escaping (Element) -> Bool = { _ in true }) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            self.filter(isIncluded)
                .subscribe { element in
                    observer(element)
                    container.dispose()
                }.toDisposeContainer(container)
            return container
        }
    }
    
    public func combineLatest<Other>(_ otherObservable: TealiumObservable<Other>) -> TealiumObservable<(Element, Other)> {
        TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            var first: Element?
            var other: Other?
            func notify() {
                if let first = first, let other = other {
                    observer((first,other))
                }
            }
            self.subscribe { element in
                first = element
                notify()
            }.toDisposeContainer(container)
            otherObservable.subscribe { element in
                other = element
                notify()
            }.toDisposeContainer(container)
            return container
        }
    }
}

public extension TealiumObservable where Element: Equatable {
    func distinct() -> TealiumObservable<Element> {
        return TealiumObservableCreate { observer in
            var lastElement: Element?
            return self.subscribe { element in
                defer { lastElement = element }
                if lastElement == nil || lastElement != element {
                   observer(element)
                }
            }
        }
    }
}
