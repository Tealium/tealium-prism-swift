//
//  SelfDestructingResultCompletion.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 17/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class that wraps a completion block and makes sure it can only be completed once.
 *
 * To be sure that the completion block is not called by someone else, you should name the variable holding the instance of this class with the same name of the completion block that was passed as a parameters.
 *
 * Example where completion block has the same parameter of the inner  function:
 * ```swift
 *  func doSomeAsyncOperation(request: URLRequest, completion: @escaping (Result<Any, Error>) -> Void) {
 *      let completion = SelfDestructingResultCompletion(completion: completion)
 *      _ = NetworkingClient.shared.send(request, completion: completion.complete)
 *  }
 * ```
 * Example where completion block has different parameters of the inner  function:
 * ```swift
 *  func doSomeAsyncOperation(request: URLRequest, completion: @escaping (Result<Any, Error>) -> Void) {
 *      let completion = SelfDestructingResultCompletion(completion: completion)
 *      URLSession.shared.dataTask(request) { data, request, error in
 *          if let error = error {
 *              completion.fail(error)
 *          } else {
 *              completion.success(data)
 *          }
 *      }.resume()
 *  }
 * ```
 * Main usecase is for completing immediately something that is cancelled, without the need to add more logic to avoid duplicate call of the completion.
 */
public class SelfDestructingResultCompletion<Success, Failure: Error>: SelfDestructingCompletion<Result<Success, Failure>> {
    /// Completes with a failure result.
    public func fail(error: Failure) {
        complete(result: .failure(error))
    }
    /// Completes with a success result.
    public func success(response: Success) {
        complete(result: .success(response))
    }
}

/**
 * A class that wraps a completion block and makes sure it can only be completed once.
 *
 * To be sure that the completion block is not called by someone else, you should name the variable holding the instance of this class with the same name of the completion block that was passed as a parameters.
 *
 * Main usecase is for completing immediately something that is cancelled, without the need to add more logic to avoid duplicate call of the completion.
 */
public class SelfDestructingCompletion<Param> {
    public typealias Completion = (Param) -> Void
    private var completion: Completion?
    public init(completion: @escaping Completion) {
        self.completion = completion
    }
    public func complete(result: Param) {
        if let completion = self.completion {
            self.completion = nil
            completion(result)
        }
    }
}
