//
//  MockTransformer.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 28/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockTransformer1: MockTransformer {
    class override var id: String { "transformer1" }
}
class MockTransformer2: MockTransformer {
    class override var id: String { "transformer2" }
}
class MockTransformer3: MockTransformer {
    class override var id: String { "transformer3" }
}

class MockTransformer: Transformer {
    var version: String = TealiumConstants.libraryVersion
    class var id: String { "MockTransformer" }
    typealias TransformationBlock = (TransformationSettings, TealiumDispatch, DispatchScope) -> TealiumDispatch?
    var transformation: TransformationBlock
    var delay: Int?
    var queue = DispatchQueue.main
    init(transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch }, delay milliseconds: Int? = nil) {
        self.transformation = transformation
        self.delay = milliseconds
    }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                completion(self.transformation(transformation, dispatch, scope))
            }
        } else {
            completion(self.transformation(transformation, dispatch, scope))
        }
    }
}
