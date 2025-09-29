//
//  ConfigurableBarrier.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// A specialist implementation of the `Barrier` that supports updated generic configuration at runtime.
public protocol ConfigurableBarrier: Barrier {
    /**
     * The unique identifier of this barrier.
     * This String will be used to match up barriers scoped in the configuration JSON.
     */
    static var id: String { get }
    /**
     * Method to notify this `Barrier` that updated `configuration` is available that may affect the
     * `Barrier`'s behavior.
     */
    func updateConfiguration(_ configuration: DataObject)
}

extension ConfigurableBarrier {
    var id: String {
        type(of: self).id
    }
}
