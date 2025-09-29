//
//  BufferedSubject.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 17/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A subject that, in addition to normal publish behavior, holds a buffer of items and sends it, in order, to the first new observer that is subscribed.
 *
 * While at least one observer is subscribed the events are not buffered anymore.
 * Buffering will resume when the last observer unsubscribes.
 */
public class BufferedSubject<Element>: BaseSubject<Element> {
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

    public override func asObservable() -> Observable<Element> {
        CustomObservable { observer in
            let buffer = self.buffer
            self.buffer = []
            defer {
                for element in buffer {
                    observer(element)
                }
            }
            self.observersCount += 1
            let sub = super.asObservable().subscribe(observer)
            return Subscription {
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
