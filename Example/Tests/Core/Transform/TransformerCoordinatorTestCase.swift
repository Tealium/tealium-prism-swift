//
//  TransformerCoordinatorTestCase.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 13/11/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// Fixtures shared by `TransformerCoordinatorDisposalTests` and `TransformerCoordinatorCompletionTests`.
class TransformerCoordinatorTestCase: XCTestCase {
    static let asyncTransformerId = "asyncTransformer"
    static let asyncTransformation = TransformationSettings(id: "first",
                                                            transformerId: asyncTransformerId,
                                                            scope: .afterCollectors)
    let testEvent = Dispatch(name: "test_event")

    /// Uses `TealiumQueue.main` by default, the queue tests run on, so batch work items are started synchronously.
    func makeCoordinator(onTransformers: Observable<[Transformer]>,
                         transformations: [TransformationSettings] = [asyncTransformation],
                         queue: TealiumQueue = TealiumQueue.main,
                         logger: LoggerProtocol? = nil) -> TransformerCoordinator {
        TransformerCoordinator(onTransformers: onTransformers,
                               transformations: StateSubject(transformations).asObservableState(),
                               queue: queue,
                               logger: logger)
    }
}
