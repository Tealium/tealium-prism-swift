//
//  SubjectReplayTestHelpers.swift
//  tealium-prism
//
//  Created by Luca Looz on 05/11/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// A linkable observer that disposes itself when it receives an element, unless created with `disposesOnNext: false`.
/// With `false` it stays subscribed, as the control for retention checks.
final class SelfDisposingObserver<Element>: LinkableObserver {
    private let linkable = SingleLinkable()
    private let disposesOnNext: Bool

    init(disposesOnNext: Bool = true) {
        self.disposesOnNext = disposesOnNext
    }

    func onNext(_ element: Element) {
        if disposesOnNext {
            dispose()
        }
    }

    func onComplete() { }

    var isDisposed: Bool { linkable.isDisposed }

    func link(_ disposable: any Disposable) {
        linkable.link(disposable)
    }

    func dispose() {
        linkable.dispose()
    }
}

/// A log shared by several `RecordingObserver`s, so a test can assert the order of events across observers.
/// Tests can also `append` their own markers, for example around a nested emit.
final class EventLog {
    private(set) var events = [String]()

    func append(_ event: String) {
        events.append(event)
    }

    func removeAll() {
        events.removeAll()
    }
}

/// An observer that records every event as a string (`"next <element>"`, `"complete"`) and calls `onElement` on each
/// element.
///
/// Several observers can record onto one shared `log`. With a `name`, each event is prefixed with `"<name>:"`.
final class RecordingObserver<Element>: Observer {
    private let log: EventLog
    private let prefix: String
    private let onElement: (Element) -> Void

    /// The events recorded onto this observer's log.
    var events: [String] { log.events }

    init(log: EventLog = EventLog(), name: String? = nil, onElement: @escaping (Element) -> Void = { _ in }) {
        self.log = log
        self.prefix = name.map { "\($0):" } ?? ""
        self.onElement = onElement
    }

    func onNext(_ element: Element) {
        log.append("\(prefix)next \(element)")
        onElement(element)
    }

    func onComplete() {
        log.append("\(prefix)complete")
    }
}

extension XCTestCase {
    /// Asserts that a combined observable receives a value emitted into its last subscribed source from the callback
    /// for the first combined value.
    ///
    /// - Parameter makeSubject: Creates the subject under test, with the given initial value.
    func assertCombineLatestReceivesValueEmittedIntoLastSource(makeSubject: (Int) -> Subject<Int>,
                                                               file: StaticString = #filePath,
                                                               line: UInt = #line) {
        let first = makeSubject(0)
        let second = makeSubject(0)
        var received = [String]()

        let subscription = first.asObservable()
            .combineLatest(second.asObservable())
            .subscribe { value1, value2 in
                received.append("(\(value1), \(value2))")
                if received.count == 1 {
                    second.onNext(1)
                }
            }
        defer { subscription.dispose() }

        XCTAssertEqual(received, ["(0, 0)", "(0, 1)"], file: file, line: line)
    }

    /// Same as `assertCombineLatestReceivesValueEmittedIntoLastSource(makeSubject:)`, for `Observables.combineLatest`.
    func assertIterableCombineLatestReceivesValueEmittedIntoLastSource(makeSubject: (Int) -> Subject<Int>,
                                                                       file: StaticString = #filePath,
                                                                       line: UInt = #line) {
        let first = makeSubject(0)
        let second = makeSubject(0)
        var received = [[Int]]()

        let subscription = Observables.combineLatest([first.asObservable(), second.asObservable()])
            .subscribe { values in
                received.append(values)
                if received.count == 1 {
                    second.onNext(1)
                }
            }
        defer { subscription.dispose() }

        XCTAssertEqual(received, [[0, 0], [0, 1]], file: file, line: line)
    }

    /// Asserts that `subject` does not keep a subscriber that disposed itself while receiving its replay.
    ///
    /// The registered observer holds the subscriber strongly, so the subscriber is released only if the subject
    /// removes the registration when the subscriber disposes itself during its replay. `subject` must emit at least
    /// one value on subscription.
    func assertSelfDisposingSubscriberIsReleased(by subject: Subject<Int>,
                                                 file: StaticString = #filePath,
                                                 line: UInt = #line) {
        weak var weakObserver: SelfDisposingObserver<Int>?
        do {
            let observer = SelfDisposingObserver<Int>()
            weakObserver = observer
            subject.asObservable().subscribeAndLink(observer)
        }

        withExtendedLifetime(subject) {
            XCTAssertNil(weakObserver,
                         "The subject holds no registration of a subscriber that disposed itself during its replay",
                         file: file,
                         line: line)
        }
    }

    /// Guards `assertSelfDisposingSubscriberIsReleased(by:)`: asserts that `subject` holds a subscriber that stays
    /// subscribed.
    func assertStayingSubscriberIsRetained(by subject: Subject<Int>,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        weak var weakObserver: SelfDisposingObserver<Int>?
        do {
            let observer = SelfDisposingObserver<Int>(disposesOnNext: false)
            weakObserver = observer
            subject.asObservable().subscribeAndLink(observer)
        }

        withExtendedLifetime(subject) {
            XCTAssertNotNil(weakObserver,
                            "The subject holds the registration of a subscriber that stays subscribed",
                            file: file,
                            line: line)
        }
    }
}
