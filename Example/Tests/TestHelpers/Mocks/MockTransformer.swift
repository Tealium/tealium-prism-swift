//
//  MockTransformer.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 28/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockTransformer: Transformer {
    let id: String
    typealias TransformationBlock = (String, TealiumDispatch, DispatchScope) -> TealiumDispatch?
    var transformation: TransformationBlock
    var delay: Int?
    var queue = DispatchQueue.main
    init(id: String, transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch }, delay milliseconds: Int? = nil) {
        self.id = id
        self.transformation = transformation
        self.delay = milliseconds
    }

    func applyTransformation(_ transformationId: String, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                completion(self.transformation(transformationId, dispatch, scope))
            }
        } else {
            completion(transformation(transformationId, dispatch, scope))
        }
    }
}
