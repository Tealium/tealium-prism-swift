//
//  SelfDestructingCompletionTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 17/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SelfDestructingCompletionTests: XCTestCase {

    func test_completion_is_only_called_once_on_success() {
        let expect = expectation(description: "Completion is only called once")
        let completion = SelfDestructingResultCompletion<Void, Error> { _ in
            expect.fulfill()
        }
        completion.success(response: ())
        completion.success(response: ())
        completion.success(response: ())
        completion.success(response: ())
        waitForDefaultTimeout()
    }

    func test_completion_is_only_called_once_on_failure() {
        let expect = expectation(description: "Completion is only called once")
        let completion = SelfDestructingResultCompletion<Void, Error> { _ in
            expect.fulfill()
        }
        let error = NetworkError.unknown(nil)
        completion.fail(error: error)
        completion.fail(error: error)
        completion.fail(error: error)
        completion.fail(error: error)
        waitForDefaultTimeout()
    }

    func test_completion_is_only_called_once_on_completion() {
        let expect = expectation(description: "Completion is only called once")
        let completion = SelfDestructingResultCompletion<Void, Error> { _ in
            expect.fulfill()
        }
        completion.complete(result: .success(()))
        completion.complete(result: .failure(NetworkError.unknown(nil)))
        completion.complete(result: .success(()))
        completion.complete(result: .failure(NetworkError.unknown(nil)))
        waitForDefaultTimeout()
    }

}
