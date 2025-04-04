//
//  DispatchContext.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// Context with information around the track that generated the Dispatch request.
public struct DispatchContext {
    public enum Source {
        /// The `TealiumDispatch` was created by the application
        case application
        /// The `TealiumDispatch` was created by a module
        case module(TealiumModule.Type)

        var moduleType: TealiumModule.Type? {
            switch self {
            case .application:
                nil
            case .module(let type):
                type
            }
        }
    }
    /// The source that generated the `TealiumDispatch`
    public let source: Source
    /// The data that was created with the `TealiumDispatch`, before any collection and transformation.
    public let initialData: DataObject
}
