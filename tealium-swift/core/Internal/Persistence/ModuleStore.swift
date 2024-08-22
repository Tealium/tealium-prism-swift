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

    @ToAnyObservable<BasePublisher<[String: TealiumDataInput]>>(BasePublisher<[String: TealiumDataInput]>())
    public var onDataUpdated: Observable<[String: TealiumDataInput]>
    private let _onDataRemoved: BasePublisher<[String]>
    public let onDataRemoved: Observable<[String]>

    init(repository: KeyValueRepository, onDataExpired: Observable<[String: TealiumDataOutput]>) {
        self.repository = repository
        let onDataRemovedPublisher = BasePublisher<[String]>()
        self._onDataRemoved = onDataRemovedPublisher
        self.onDataRemoved = onDataExpired.map { expiredData in expiredData.keys.map { String($0) } }.merge(onDataRemovedPublisher.asObservable())
    }

    public func edit() -> DataStoreEditor {
        return Editor(repository: repository) { [weak self] edits in
            guard let self = self else { return }
            var removedKeys = [String]()
            var updatedData = [String: TealiumDataInput]()
            for edit in edits {
                switch edit {
                case let .remove(key):
                    removedKeys.append(key)
                case let .put(key, value, _):
                    updatedData[key] = value
                }
            }
            if !removedKeys.isEmpty {
                self._onDataRemoved.publish(removedKeys)
            }
            if !updatedData.isEmpty {
                self._onDataUpdated.publish(updatedData)
            }
        }
    }

    public func get(key: String) -> TealiumDataOutput? {
        repository.get(key: key)
    }

    public func getAll() -> [String: TealiumDataOutput] {
        repository.getAll()
    }

    public func keys() -> [String] {
        repository.keys()
    }

    public func count() -> Int {
        repository.count()
    }

    enum Edit {
        case remove(String)
        case put(String, TealiumDataInput, Expiry)
    }

    class Editor: DataStoreEditor {
        let repository: KeyValueRepository
        var shouldClear = false
        var committed = false
        var edits = [Edit]()
        let completion: ([Edit]) -> Void

        init(repository: KeyValueRepository, completion: @escaping ([Edit]) -> Void) {
            self.repository = repository
            self.completion = completion
        }

        func put(key: String, value: TealiumDataInput, expiry: Expiry) -> Self {
            edits.append(.put(key, value, expiry))
            return self
        }

        func putAll(dictionary: TealiumDictionaryInput, expiry: Expiry) -> Self {
            for (key, value) in dictionary {
                _ = put(key: key, value: value, expiry: expiry)
            }
            return self
        }

        func remove(key: String) -> Self {
            edits.append(.remove(key))
            return self
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

        private func apply(_ edit: Edit, on repository: KeyValueRepository) throws -> Bool {
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
            var appliedEdits = [Edit]()
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
