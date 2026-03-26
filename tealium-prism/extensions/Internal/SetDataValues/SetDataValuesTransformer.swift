//
//  SetDataValuesTransformer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if extensions
import TealiumPrismCore
#endif

class SetDataValuesTransformer: Transformer, BasicModule {
    let id: String = Modules.Types.setDataValuesTransformer
    let version: String = TealiumConstants.libraryVersion

    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init()
    }

    init() { }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) {
        guard let configuration = SetDataValuesConfiguration(dataObject: transformation.configuration) else {
            completion(dispatch)
            return
        }
        completion(applyTransformation(configuration, to: dispatch))
    }

    private func applyTransformation(_ config: SetDataValuesConfiguration,
                                     to dispatch: Dispatch) -> Dispatch {
        var payload = dispatch.payload
        for operation in config.operations {
            switch operation.input {
            case .reference(let reference):
                guard let item = payload.extractDataItem(path: reference.path) else {
                    continue
                }
                payload.buildPath(operation.destination.path, andSet: item)
            case .constant(let value):
                payload.buildPath(operation.destination.path, andSet: value.value)
            }
        }
        var updatedDispatch = dispatch
        updatedDispatch.replace(payload: payload)
        return updatedDispatch
    }
}
