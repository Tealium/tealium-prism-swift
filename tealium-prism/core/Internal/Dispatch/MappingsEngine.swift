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
    var filter: StringContainer? {
        parameters.filter
    }
    var mapTo: ValueContainer? {
        parameters.mapTo
    }
}

class MappingsEngine {
    private static let commandNamePath = JSONPath[TealiumDataKey.commandName]

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
     * Applies the `mappings` on top of the `dispatch` payload.
     *
     * Keys and values that are not described in the `mappings` are kept as they are, while any value
     * already present at a mapped destination is replaced by the mapped value.
     * The only exception is the root "command_name" key: mapped values are always appended to any value already there
     * (from the original payload or from an earlier mapping), flattening arrays one level, so that multiple commands can be collected
     * (e.g. an existing `["a"]` with a mapped `["b", ["c"]]` gives `["a", "b", ["c"]]`).
     *
     * Sources and filters are always read from the original `Dispatch.payload`, so mappings don't chain:
     * a mapping can't read the result of another mapping.
     * An empty list of `mappings` leaves the payload unchanged.
     *
     * - Parameters:
     *      - dispatch: The incoming `Dispatch` whose payload is expected to be mapped to the resulting `Dispatch`
     *      - mappings: The list of mappings to apply, in order.
     */
    func map(dispatch: Dispatch, mappings: [MappingOperation]) -> Dispatch {
        var dispatch = dispatch
        var result = dispatch.payload
        for mapping in mappings {
            applyMapping(mapping, from: dispatch.payload, to: &result)
        }
        dispatch.payload = result
        return dispatch
    }

    private func applyMapping(_ mapping: MappingOperation,
                              from payload: DataObject,
                              to result: inout DataObject) {
        guard let mapped = getMappedValue(payload: payload, mapping: mapping) else {
            return
        }
        let path = mapping.destination.path
        let itemToInsert: DataItem
        if path == Self.commandNamePath, let itemToReplace = result.extractDataItem(path: path) {
            var array = itemToReplace.getDataArray() ?? [itemToReplace]
            array.append(contentsOf: mapped.getDataArray() ?? [mapped])
            itemToInsert = DataItem(converting: array)
        } else {
            itemToInsert = mapped
        }
        result.buildPath(path, andSet: itemToInsert)
    }

    private func getMappedValue(payload: DataObject, mapping: MappingOperation) -> DataItem? {
        let extracted = mapping.path.flatMap { payload.extractDataItem(path: $0) }
        guard isFilter(mapping.filter?.value, matching: extracted?.value) else {
            return nil
        }
        let mapTo = mapping.mapTo?.value
        if let mapTo {
            return mapTo
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
