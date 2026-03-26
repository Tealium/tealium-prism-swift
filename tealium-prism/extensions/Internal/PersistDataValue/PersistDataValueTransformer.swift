//
//  PersistDataValueTransformer.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

extension LogCategory {
    static let persistDataValue = "PersistDataValue"
}

class PersistDataValueTransformer: Transformer, BasicModule {
    let id: String = Modules.Types.persistDataValueTransformer
    let version: String = TealiumConstants.libraryVersion

    private let logger: LoggerProtocol?
    private let dataLayer: any DataStore
    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(logger: context.logger, dataLayer: context.dataLayer)
    }

    init(logger: LoggerProtocol?, dataLayer: any DataStore) {
        self.logger = logger
        self.dataLayer = dataLayer
    }

    func applyTransformation(
        _ transformation: TransformationSettings,
        to dispatch: Dispatch,
        scope: DispatchScope,
        completion: @escaping (Dispatch?) -> Void
    ) {
        guard let config = PersistDataValueConfiguration(dataObject: transformation.configuration) else {
            completion(dispatch)
            return
        }
        applyTransformation(config, to: dispatch, completion: completion)
    }

    private func applyTransformation(_ config: PersistDataValueConfiguration,
                                     to dispatch: Dispatch,
                                     completion: @escaping (Dispatch?) -> Void) {
        let payload = dispatch.payload
        let destinationPath = config.destination.path

        if config.updatePolicy == .keepFirstValue {
            if dataLayer.extractDataItem(path: destinationPath) != nil {
                completion(dispatch)
                return
            }
        }

        let valueToStore: DataItem? = switch config.input {
        case .reference(let reference):
            payload.extractDataItem(path: reference.path)
        case .constant(let value):
            value.value
        }

        guard let valueToStore else {
            completion(dispatch)
            return
        }

        do {
            try dataLayer.buildPath(
                destinationPath,
                andSet: valueToStore,
                expiry: config.expiryPolicy.resolve()
            )
            var updatedPayload = dispatch.payload
            updatedPayload.buildPath(destinationPath, andSet: valueToStore)
            var updatedDispatch = dispatch
            updatedDispatch.replace(payload: updatedPayload)
            completion(updatedDispatch)
        } catch {
            logger?.error(category: LogCategory.persistDataValue, "PersistDataValue failed to persist path '\(destinationPath.render())': \(error)")
            completion(dispatch)
        }
    }
}
