//
//  BatchingBarrierSettingsBuilder.swift
//  tealium-prism
//
//  Created by Den Guzov on 09/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to configure the `BatchingBarrier` settings.
public class BatchingBarrierSettingsBuilder: BarrierSettingsBuilder {
    typealias Keys = BatchingBarrierConfiguration.Keys

    /// Set the batch size for dispatches.
    /// When this number of dispatches is reached, the batch will be released.
    /// - Parameter batchSize: The number of dispatches in a batch. Default value of 1 will be used if argument is negative or zero.
    /// - Returns: The builder instance for method chaining.
    public func setBatchSize(_ batchSize: Int) -> Self {
        _configurationObject.set(batchSize, key: Keys.batchSize)
        return self
    }
}
