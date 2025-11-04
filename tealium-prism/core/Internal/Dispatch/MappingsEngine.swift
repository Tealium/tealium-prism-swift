//
//  MappingsEngine.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

typealias MappingOperation = TransformationOperation<MappingParameters>

extension MappingOperation {
    var path: JSONObjectPath? {
        parameters.reference?.path
    }
    var filter: ValueContainer? {
        parameters.filter
    }
    var mapTo: ValueContainer? {
        parameters.mapTo
    }
}

class MappingsEngine {
    private let mappings: ObservableState<[String: [MappingOperation]]>

    init(mappings: ObservableState<[String: [MappingOperation]]>) {
        self.mappings = mappings
    }

    /**
     * Fetches any mappings for the given `dispatcherId`, and applies them to the `dispatch`
     *
     * If no mappings are found, then the `dispatch` is returned unaffected.
     */
    func map(dispatcherId: String, dispatch: Dispatch) -> Dispatch {
        guard let dispatcherMappings = mappings.value[dispatcherId] else {
            return dispatch
        }
        return map(dispatch: dispatch, mappings: dispatcherMappings)
    }

    /**
     * Remaps the `dispatch` according to the provided `mappings`.
     *
     * The `mappings` describe which keys and values to take from the `Dispatch.payload` and place into a new
     * `DataObject` that will replace the data inside the `dispatch`, which is returned.
     *
     * The returned `Dispatch` will have a payload built from an empty `DataObject`, such that keys/values
     * that are not described in the `mappings` will be lost.
     *
     * - Parameters:
     *      - dispatch: The incoming `Dispatch` whose payload is expected to be mapped to the resulting `Dispatch`
     *      - mappings: The list of mappings to apply, in order.
     */
    func map(dispatch: Dispatch, mappings: [MappingOperation]) -> Dispatch {
        var dispatch = dispatch
        var result = DataObject()
        for mapping in mappings {
            applyMapping(mapping, from: dispatch.payload, to: &result)
        }
        dispatch.payload = result
        return dispatch
    }

    private func applyMapping(_ mapping: MappingOperation, from payload: DataObject, to result: inout DataObject) {
        guard let mapped = getMappedValue(payload: payload, mapping: mapping) else {
            return
        }
        let shouldCombineResults = mapping.mapTo != nil
        let itemToInsert: DataItem
        if shouldCombineResults, let itemToReplace = result.extractDataItem(path: mapping.destination.path) {
            var array = itemToReplace.getDataArray() ?? [itemToReplace]
            array.append(mapped)
            itemToInsert = DataItem(converting: array)
        } else {
            itemToInsert = mapped
        }
        result.buildPath(mapping.destination.path,
                         andSet: itemToInsert)
    }

    private func getMappedValue(payload: DataObject, mapping: MappingOperation) -> DataItem? {
        let extracted: DataItem? = if let path = mapping.path {
            payload.extractDataItem(path: path)
        } else { nil }
        guard isFilter(mapping.filter?.value, matching: extracted?.value) else {
            return nil
        }
        let mapTo = mapping.mapTo?.value
        if let mapTo {
            return DataItem(value: mapTo)
        } else {
            return extracted
        }
    }

    private func isFilter(_ filter: String?, matching value: Any?) -> Bool {
        guard let filter else {
            return true
        }
        guard let value else {
            return false
        }
        return filter == "\(value)"
    }
}
