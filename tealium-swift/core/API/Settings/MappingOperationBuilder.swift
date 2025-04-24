//
//  MappingOperationBuilder.swift
//  tealium-swift
//
//  Created by Tealium on 22/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder class for creating `TransformationOperation<MappingParameters>` instances.
public class MappingOperationBuilder {
    private let key: VariableAccessor
    private let destination: VariableAccessor
    private var filter: ValueContainer?
    private var mapTo: ValueContainer?

    /// Creates a new mapping operation builder with the specified source and destination.
    /// - Parameters:
    ///   - key: The source variable accessor.
    ///   - destination: The destination variable accessor.
    /// - Returns: A new mapping operation builder.
    public static func from(_ key: VariableAccessor, to destination: VariableAccessor) -> MappingOperationBuilder {
        MappingOperationBuilder(key: key, destination: destination)
    }

    init(key: VariableAccessor, destination: VariableAccessor) {
        self.key = key
        self.destination = destination
    }

    /// Sets a filter condition that the variable must match to be mapped.
    /// - Parameter value: The value that the variable needs to equal.
    /// - Returns: The builder instance for chaining.
    public func ifInputEquals(_ value: String) -> Self {
        self.filter = ValueContainer(value)
        return self
    }

    /// Sets the value to be put at the destination.
    /// - Parameter value: The value that needs to be put at the destination.
    /// - Returns: The builder instance for chaining.
    public func mapTo(_ value: String) -> Self {
        self.mapTo = ValueContainer(value)
        return self
    }

    /// Builds and returns a `TransformationOperation<MappingParameters>` instance.
    /// - Returns: The constructed transformation operation.
    func build() -> TransformationOperation<MappingParameters> {
        let parameters = MappingParameters(key: key, filter: filter, mapTo: mapTo)
        return TransformationOperation(destination: destination, parameters: parameters)
    }
}
