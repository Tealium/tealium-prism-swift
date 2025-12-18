//
//  LowerCaseTransformer.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
    import TealiumPrismCore
#endif

class LowerCaseTransformer: Transformer, BasicModule {
    let id: String = Modules.Types.lowerCaseTransformer
    let version: String = "1.0.0"

    required init?(context: TealiumContext, moduleConfiguration: DataObject) {}

    func applyTransformation(
        _ transformation: TransformationSettings,
        to dispatch: Dispatch,
        scope: DispatchScope,
        completion: @escaping (Dispatch?) -> Void
    ) {
        let configuration = LowerCaseConfiguration(dataObject: transformation.configuration)
        completion(applyTransformation(configuration, to: dispatch))
    }

    private func applyTransformation(
        _ config: LowerCaseConfiguration,
        to dispatch: Dispatch
    ) -> Dispatch {
        var payload = dispatch.payload

        if config.allVariables {
            // Lowercase all string values in the payload
            payload = lowercaseAllStrings(in: payload)
        } else {
            // Only lowercase specific operations
            for operation in config.operations {
                if let item = payload.extractDataItem(
                    path: operation.parameters.input.path
                ),
                    let stringValue = item.get(as: String.self) {
                        let lowercased = stringValue.lowercased()
                        payload.buildPath(
                            operation.destination.path,
                            andSet: DataItem(value: lowercased)
                        )
                    }
            }
        }

        return Dispatch(
            payload: payload,
            id: dispatch.id,
            timestamp: dispatch.timestamp
        )
    }

    private func lowercaseAllStrings(in dataObject: DataObject) -> DataObject {
        var result = DataObject()
        for key in dataObject.keys {
            if let item = dataObject.getDataItem(key: key) {
                result.set(converting: lowercaseDataItem(item), key: key)
            }
        }
        return result
    }

    private func lowercaseDataItem(_ item: DataItem) -> DataItem {
        if let stringValue = item.get(as: String.self) {
            return DataItem(value: stringValue.lowercased())
        } else if let array = item.getDataArray() {
            return DataItem(converting: array.map { lowercaseDataItem($0) })
        } else if let dict = item.getDataDictionary() {
            return DataItem(
                converting: dict.mapValues { lowercaseDataItem($0) }
            )
        }
        return item
    }
}
