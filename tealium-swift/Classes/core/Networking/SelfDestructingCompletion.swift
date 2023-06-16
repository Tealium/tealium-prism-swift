//
//  SelfDestructingCompletion.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 17/05/23.
//

import Foundation

class SelfDestructingCompletion<Success, Failure: Error> {
    typealias Param = Result<Success, Failure>
    typealias Completion = (Param) -> Void
    private var completion: Completion?
    init(completion: @escaping Completion) {
        self.completion = completion
    }
    func complete(result: Param) {
        if let completion = self.completion {
            self.completion = nil
            completion(result)
        }
    }
    func fail(error: Failure) {
        complete(result: .failure(error))
    }
    func success(response: Success) {
        complete(result: .success(response))
    }
}
