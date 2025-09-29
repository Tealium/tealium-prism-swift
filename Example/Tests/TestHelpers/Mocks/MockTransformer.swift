//
//  MockTransformer.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 28/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism

class MockTransformer1: MockTransformer {
    class override var moduleType: String { "transformer1" }
    override init(moduleId: String = MockTransformer1.moduleType,
                  transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
                  delay milliseconds: Int? = nil) {
        super.init(moduleId: moduleId, transformation: transformation, delay: milliseconds)
    }
}
class MockTransformer2: MockTransformer {
    class override var moduleType: String { "transformer2" }
    override init(moduleId: String = MockTransformer2.moduleType,
                  transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
                  delay milliseconds: Int? = nil) {
        super.init(moduleId: moduleId, transformation: transformation, delay: milliseconds)
    }
}
class MockTransformer3: MockTransformer {
    class override var moduleType: String { "transformer3" }
    override init(moduleId: String = MockTransformer3.moduleType,
                  transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
                  delay milliseconds: Int? = nil) {
        super.init(moduleId: moduleId, transformation: transformation, delay: milliseconds)
    }
}

class MockTransformer: Transformer {
    static var allowsMultipleInstances: Bool = true
    let version: String = TealiumConstants.libraryVersion
    class var moduleType: String { "MockTransformer" }
    let id: String
    typealias TransformationBlock = (TransformationSettings, Dispatch, DispatchScope) -> Dispatch?
    var transformation: TransformationBlock
    var delay: Int?
    var queue = DispatchQueue.main
    init(moduleId: String = MockTransformer.moduleType,
         transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch },
         delay milliseconds: Int? = nil) {
        self.id = moduleId
        self.transformation = transformation
        self.delay = milliseconds
    }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) {
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                completion(self.transformation(transformation, dispatch, scope))
            }
        } else {
            completion(self.transformation(transformation, dispatch, scope))
        }
    }
}
