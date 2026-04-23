//
//  LowercaseTransformer.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
import TealiumPrismCore
#endif

class LowercaseTransformer: Transformer, BasicModule {
    let id: String = Modules.Types.lowercaseTransformer
    let version: String = TealiumConstants.libraryVersion

    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init()
    }

    init() {}

    func applyTransformation(
        _ transformation: TransformationSettings,
        to dispatch: Dispatch,
        scope: DispatchScope,
        completion: @escaping (Dispatch?) -> Void
    ) {
        guard let configuration = LowercaseConfiguration(dataObject: transformation.configuration) else {
            completion(dispatch)
            return
        }
        completion(applyTransformation(configuration, to: dispatch))
    }

    private func applyTransformation(
        _ config: LowercaseConfiguration,
        to dispatch: Dispatch
    ) -> Dispatch {
        var payload = dispatch.payload

        switch config.policy {
        case .allVariables:
            payload = lowercaseAllStrings(in: payload)
        case .variables(let variables):
            for variable in variables {
                guard let item = payload.extractDataItem(path: variable.path) else { continue }
                payload.buildPath(variable.path, andSet: lowercaseDataItem(item))
            }
        }

        var result = dispatch
        result.replace(payload: payload)
        return result
    }

    private func lowercaseAllStrings(in dataObject: DataObject) -> DataObject {
        var result = DataObject()
        for key in dataObject.keys {
            guard let item = dataObject.getDataItem(key: key) else { continue }
            result.set(converting: shouldExclude(key) ? item : lowercaseDataItem(item), key: key)
        }
        return result
    }

    private static let excludedKeys: Set<String> = [
        TealiumDataKey.visitorId, TealiumDataKey.cpTraceId, TealiumDataKey.tealiumTraceId
    ]

    private func shouldExclude(_ key: String) -> Bool {
        LowercaseTransformer.excludedKeys.contains(key)
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
