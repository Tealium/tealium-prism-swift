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

class PersistDataValueTransformer: Transformer, BasicModule {
    let id: String = Modules.Types.persistDataValueTransformer
    let version: String = TealiumConstants.libraryVersion

    private let modulesManager: ModulesManager
    private let logger: LoggerProtocol?
    private let dataLayer: any DataStore
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.modulesManager = context.modulesManager
        self.logger = context.logger
        self.dataLayer = context.dataLayer
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

        if config.updateBehavior == .keepFirstValue {
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
                expiry: config.expiry
            )
        } catch {
            logger?.error(category: LogCategory.transformations, "PersistDataValue failed to persist path '\(destinationPath.render())': \(error)")
        }

        completion(dispatch)
    }
}
