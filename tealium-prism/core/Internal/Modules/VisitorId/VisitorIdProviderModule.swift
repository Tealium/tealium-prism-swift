//
//  VisitorIdProviderModule.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 24/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

class VisitorIdProviderModule: BasicModule {
    let version: String = TealiumConstants.libraryVersion
    static let canBeDisabled: Bool = false
    static let moduleType: String = Modules.Types.visitorIdProvider
    var id: String { Self.moduleType }
    let storage: VisitorIdStorage

    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(storage: context.visitorIdStorage)
    }

    init(storage: VisitorIdStorage) {
        self.storage = storage
    }

    func getVisitorId() -> String {
        storage.visitorId.value
    }

    func reset() throws -> String {
        try storage.resetVisitorId()
    }

    func clearStored() throws -> String {
        try storage.clearStoredVisitorIds()
    }
}
