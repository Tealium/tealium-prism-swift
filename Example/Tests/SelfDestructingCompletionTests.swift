//
//  SelfDestructingCompletionTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/05/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import tealium_swift

final class SelfDestructingCompletionTests: XCTestCase {

    func test_completion_is_only_called_once_on_success() {
        let expect = expectation(description: "Completion is only called once")
        let completion = SelfDestructingCompletion<Void, Error> { _ in
            expect.fulfill()
        }
        completion.success(response: ())
        completion.success(response: ())
        completion.success(response: ())
        completion.success(response: ())
        waitForExpectations(timeout: 1.0)
    }
    
    func test_completion_is_only_called_once_on_failure() {
        let expect = expectation(description: "Completion is only called once")
        let completion = SelfDestructingCompletion<Void, Error> { _ in
            expect.fulfill()
        }
        completion.fail(error: NSError())
        completion.fail(error: NSError())
        completion.fail(error: NSError())
        completion.fail(error: NSError())
        waitForExpectations(timeout: 1.0)
    }
    
    func test_completion_is_only_called_once_on_completion() {
        let expect = expectation(description: "Completion is only called once")
        let completion = SelfDestructingCompletion<Void, Error> { _ in
            expect.fulfill()
        }
        completion.complete(result: .success(()))
        completion.complete(result: .failure(NSError()))
        completion.complete(result: .success(()))
        completion.complete(result: .failure(NSError()))
        waitForExpectations(timeout: 1.0)
    }

}
