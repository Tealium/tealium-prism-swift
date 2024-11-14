//
//  ModuleStore.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModuleStore: DataStore {

    private let repository: KeyValueRepository

    @ToAnyObservable<BasePublisher<DataObject>>(BasePublisher<DataObject>())
    public var onDataUpdated: Observable<DataObject>
    private let _onDataRemoved: BasePublisher<[String]>
    public let onDataRemoved: Observable<[String]>

    init(repository: KeyValueRepository, onDataExpired: Observable<[String: DataItem]>) {
        self.repository = repository
        let onDataRemovedPublisher = BasePublisher<[String]>()
        self._onDataRemoved = onDataRemovedPublisher
        self.onDataRemoved = onDataExpired.map { expiredData in expiredData.keys.map { String($0) } }.merge(onDataRemovedPublisher.asObservable())
    }

    public func edit() -> DataStoreEditor {
        return Editor(repository: repository) { [weak self] edits in
            guard let self = self else { return }
            var removedKeys = [String]()
            var updatedData = DataObject()
            for edit in edits {
                switch edit {
                case let .remove(key):
                    removedKeys.append(key)
                case let .put(key, value, _):
                    updatedData.set(value, key: key)
                }
            }
            if !removedKeys.isEmpty {
                self._onDataRemoved.publish(removedKeys)
            }
            if updatedData.count > 0 {
                self._onDataUpdated.publish(updatedData)
            }
        }
    }

    public func getDataItem(key: String) -> DataItem? {
        repository.get(key: key)
    }

    public func getAll() -> DataObject {
        repository.getAll()
    }

    public func keys() -> [String] {
        repository.keys()
    }

    public func count() -> Int {
        repository.count()
    }

    class Editor: DataStoreEditor {
        let repository: KeyValueRepository
        var shouldClear = false
        var committed = false
        var edits = [DataStoreEdit]()
        let completion: ([DataStoreEdit]) -> Void

        init(repository: KeyValueRepository, completion: @escaping ([DataStoreEdit]) -> Void) {
            self.repository = repository
            self.completion = completion
        }

        func apply(edit: DataStoreEdit) -> Self {
            edits.append(edit)
            return self
        }

        func put(key: String, value: DataInput, expiry: Expiry) -> Self {
            apply(edit: .put(key, value, expiry))
        }

        func putAll(dataObject: DataObject, expiry: Expiry) -> Self {
            for (key, value) in dataObject.asDictionary() {
                _ = put(key: key, value: value, expiry: expiry)
            }
            return self
        }

        func remove(key: String) -> Self {
            apply(edit: .remove(key))
        }

        func remove(keys: [String]) -> Self {
            for key in keys {
                _ = remove(key: key)
            }
            return self
        }

        func clear() -> Self {
            shouldClear = true
            return self
        }

        private func apply(_ edit: DataStoreEdit, on repository: KeyValueRepository) throws -> Bool {
            switch edit {
            case let .remove(key):
                let affectedRows = try repository.delete(key: key)
                return affectedRows > 0
            case let .put(key, value, expiry):
                try repository.upsert(key: key, value: value, expiry: expiry)
            }
            return true
        }

        func commit() throws {
            guard !committed else { return }
            let isThereSomethingToCommit = !edits.isEmpty || shouldClear
            guard isThereSomethingToCommit else { return }
            committed = true
            var appliedEdits = [DataStoreEdit]()
            try repository.transactionally { repo in
                if shouldClear {
                    appliedEdits.append(contentsOf: repo.keys().map { .remove($0) })
                    _ = try repo.clear()
                }
                for edit in edits where try apply(edit, on: repo) {
                    appliedEdits.append(edit)
                }
            }
            completion(appliedEdits)
        }
    }
}
