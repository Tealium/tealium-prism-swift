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
    init(id: String, transformation: @escaping TransformationBlock = { _, dispatch, _ in dispatch }) {
        self.id = id
        self.transformation = transformation
    }

    func applyTransformation(_ transformationId: String, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        completion(transformation(transformationId, dispatch, scope))
    }
}
