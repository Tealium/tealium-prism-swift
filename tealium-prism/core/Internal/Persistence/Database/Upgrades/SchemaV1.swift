//
//  SchemaV1.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/// The table and column names of database version 1, as plain `String`s because upgrade steps write raw SQL.
///
/// This is a frozen snapshot: it is never edited. A later version that changes the shape adds `SchemaV{N}`;
/// one that doesn't adds a `typealias` to the previous snapshot.
enum SchemaV1 {

    enum Module {
        static let table = "module"
        static let id = "id"
        static let name = "name"
    }

    enum ModuleStorage {
        static let table = "module_storage"
        static let moduleId = "module_id"
        static let key = "key"
        static let value = "value"
        static let expiry = "expiry"
    }

    enum Dispatch {
        static let table = "dispatch"
        static let uuid = "uuid"
        static let timestamp = "timestamp"
        static let dispatch = "dispatch"
    }

    enum Queue {
        static let table = "queue"
        static let dispatchId = "dispatch_id"
        static let processor = "processor"
    }
}
