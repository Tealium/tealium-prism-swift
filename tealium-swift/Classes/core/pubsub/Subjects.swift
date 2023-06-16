//
//  Subjects.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumSubjectProtocol: TealiumObservableProtocol, TealiumPublisherProtocol {
}

public extension TealiumSubjectProtocol {

    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> TealiumDisposableProtocol {
        asObservable().subscribe(observer)
    }
}
public class TealiumPublishSubject<Element>: TealiumPublisher<Element>, TealiumSubjectProtocol {
}

// MARK: Replay

//TODO: Check this might be broken
public class TealiumReplaySubject<Element>: TealiumPublishSubject<Element> {
    private let cacheSize: Int?
    private var cache = [Element]()
    // Having a default value here would cause a crash on Carthage
    public init(cacheSize: Int?) {
        self.cacheSize = cacheSize
    }

    convenience public override init() {
        self.init(cacheSize: 1)
    }
    
    public override func asObservable() -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let cache = self.cache
            defer {
                for element in cache {
                    observer(element)
                }
            }
            return super.asObservable().subscribe(observer)
        }
    }
    public override func publish(_ element: Element) {
        while let size = cacheSize, cache.count >= size && cache.count > 0 {
            cache.remove(at: 0)
        }
        if cacheSize == nil || cacheSize > 0 {
            cache.append(element)
        }
        super.publish(element)
    }

    public func clear() {
        cache.removeAll()
    }

    public func last() -> Element? {
        return cache.last
    }

}

// MARK: Buffered

public class TealiumBufferedSubject<Element>: TealiumPublishSubject<Element> {
    private let bufferSize: Int?
    private var buffer = [Element]()
    private var observersCount = 0
    // Having a default value here would cause a crash on Carthage
    public init(bufferSize: Int?) {
        self.bufferSize = bufferSize
    }

    convenience public override init() {
        self.init(bufferSize: 1)
    }

    public override func asObservable() -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let buffer = self.buffer
            self.buffer = []
            defer {
                for element in buffer {
                    observer(element)
                }
            }
            self.observersCount += 1
            let sub = super.asObservable().subscribe(observer)
            return TealiumSubscription {
                self.observersCount -= 1
                sub.dispose()
            }
        }
    }
    public override func publish(_ element: Element) {
        if self.observersCount <= 0 {
            while let size = bufferSize, buffer.count >= size && buffer.count > 0 {
                buffer.remove(at: 0)
            }
            if bufferSize == nil || bufferSize > 0 {
                buffer.append(element)
            }
        }
        super.publish(element)
    }
}

private extension Optional where Wrapped == Int {

    static func > (lhs: Int?, rhs: Int) -> Bool {
        if let value = lhs {
            return value > rhs
        }
        return false
    }

}
