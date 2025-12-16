//
//  TransformationSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

open class TransformationSettingsBuilder {
    let id: String
    let transformerId: String
    var conditions: Rule<Condition>?
    var scopes: [TransformationScope] = []
    var configuration: DataObject = [:]

    public init(id: String, transformerId: String) {
        self.id = id
        self.transformerId = transformerId
    }

    public func setScopes(_ scopes: [TransformationScope]) -> Self {
        self.scopes = scopes
        return self
    }

    public func addScope(_ scope: TransformationScope) -> Self {
        scopes.append(scope)
        return self
    }

    public func setConditions(_ conditions: Rule<Condition>) -> Self {
        self.conditions = conditions
        return self
    }

    // Do not use
    public func _setConfiguration(_ configuration: DataObject) -> Self {
        self.configuration = configuration
        return self
    }

    public func build() -> TransformationSettings {
        TransformationSettings(id: id,
                               transformerId: transformerId,
                               scopes: scopes,
                               configuration: configuration,
                               conditions: conditions)
    }

}
