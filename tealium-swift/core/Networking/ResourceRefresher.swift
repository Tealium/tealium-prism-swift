//
//  ResourceRefresher.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * An object that refreshes a single resource at regular intervals.
 *
 * Refresh is requested by the user of ths class, but it's ignored unless the required intervals have passed.
 * The resource is cached locally and it's re-read only on initialization or when subscribing `onResourceLoaded`.
 *
 * You can listen to resource updates by using the `onResourceLoaded` observable.
 * This will first push an event with a resource read from disk, if present, and then all refreshes from remote.
 */
public class ResourceRefresher<Resource: Codable> {
    let dataStore: DataStore
    private var parameters: RefreshParameters
    public var id: String {
        parameters.id
    }
    var etagStorageKey: String {
        parameters.fileName + "_etag"
    }
    private var fetching: Bool {
        disposableRequest != nil
    }
    private var lastFetch: Date?
    /// An in memory state to remember if the file is cached, to avoiding reading from disk every time.
    lazy private(set) var isFileCached: Bool = readResource() != nil
    private(set) var lastEtag: String?
    private let errorCooldown: ErrorCooldown?
    private let networkHelper: NetworkHelperProtocol
    private let logger: TealiumLogger?

    private let _onResourceLoaded = TealiumPublisher<Resource>()
    /// An observable sequence of resources, starting from whatever might be cached on disk, and followed with all the subsequent successful refreshes.
    public var onResourceLoaded: TealiumObservable<Resource> {
        TealiumObservable.Just(readResource())
            .compactMap { [weak self] resource in
                if resource != nil {
                    self?.isFileCached = true
                }
                return resource
            }
            .merge(_onResourceLoaded.asObservable())
    }

    /**
     * An observable sequence of errors that might come from network or from failing to write the cached resource on disk.
     *
     * Note that 304 errors are ignored as they are the intended network response when the resource was not modified.
     */
    @ToAnyObservable<TealiumPublisher<Error>>(TealiumPublisher<Error>())
    public var onRefreshError: TealiumObservable<Error>

    private var disposableRequest: TealiumDisposable?

    public init(networkHelper: NetworkHelperProtocol,
                dataStore: DataStore,
                parameters: RefreshParameters,
                errorCooldown: ErrorCooldown?,
                logger: TealiumLogger? = nil) {
        self.networkHelper = networkHelper
        self.dataStore = dataStore
        self.parameters = parameters
        self.errorCooldown = errorCooldown ?? ErrorCooldown(baseInterval: parameters.errorCooldownBaseInterval,
                                                            maxInterval: parameters.refreshInterval)
        self.logger = logger
        if lastEtag == nil && isFileCached {
            lastEtag = dataStore.getString(key: etagStorageKey)
        }
    }

    var shouldRefresh: Bool {
        guard !fetching else {
            return false
        }
        guard let lastFetch = lastFetch else {
            return true
        }
        guard errorCooldown == nil || isFileCached else {
            return errorCooldown?.isInCooldown(lastFetch: lastFetch) == false
        }
        guard let newFetchMinimumDate = lastFetch.addSeconds(parameters.refreshInterval) else {
            return true
        }
        return newFetchMinimumDate < Date()
    }

    /**
     * Requests a refresh that is fulfilled if enough time has passed and, optionally,
     * pass a callback to validate the resource and define if it should be accepted and cached.
     *
     * Only valid resources are reported in the `onResourceLoaded` callback and stored on disk.
     *
     * - Parameters:
     *  - validatingResource: A callback that passes the refreshed resource as a parameter and needs to return `true` if the resource is valid or `false` if it is not valid.
     */
    public func requestRefresh(validatingResource: @escaping (Resource) -> Bool = { _ in true }) {
        guard shouldRefresh else {
            return
        }
        refresh(validatingResource: validatingResource)
    }

    private func refresh(validatingResource: @escaping (Resource) -> Bool) {
        disposableRequest = networkHelper.getJsonAsObject(url: parameters.url, etag: lastEtag) { [weak self] (result: ObjectResult<Resource>) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                if validatingResource(response.object) {
                    self.logger?.debug?.log(category: "ResourceRefresher",
                                            message: "Refreshed resource \(id)")
                    self.saveResource(response.object, etag: response.urlResponse.etag)
                    self._onResourceLoaded.publish(response.object)
                } else {
                    self.logger?.debug?.log(category: "ResourceRefresher",
                                            message: "Downloaded resource \(id) but discarded as not valid")
                }
                self.errorCooldown?.newCooldownEvent(error: nil)
            case .failure(let error):
                if case let .non200Status(code) = error, code == 304 {
                    self.logger?.trace?.log(category: "ResourceRefresher",
                                            message: "Resource \(id) is not modified")
                    self.errorCooldown?.newCooldownEvent(error: nil)
                } else {
                    self.logger?.error?.log(category: "ResourceRefresher",
                                            message: "Failed to refresh resource \(id) due to error\n\(error)")
                    self._onRefreshError.publish(error)
                    self.errorCooldown?.newCooldownEvent(error: error)
                }
            }
            self.lastFetch = Date()
            self.disposableRequest = nil
        }
    }

    public func readResource() -> Resource? {
        guard let stringValue = dataStore.getString(key: parameters.fileName) else {
            return nil
        }
        return try? stringValue.deserializeCodable()
    }

    private func serialize(resource: Resource) throws -> String {
        let jsonEncoder = Tealium.jsonEncoder
        let jsonData = try jsonEncoder.encode(resource)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw TealiumDataValueErrors.dataToStringFailed
        }
        return jsonString
    }

    func saveResource(_ resource: Resource, etag: String?) {
        do {
            let serializedResource = try serialize(resource: resource)
            var edit = dataStore.edit()
                .put(key: parameters.fileName, value: serializedResource, expiry: .forever)
            if let etag = etag {
                edit = edit.put(key: etagStorageKey, value: etag, expiry: .forever)
            } else {
                edit = edit.remove(key: etagStorageKey)
            }
            try edit.commit()
            lastEtag = etag
            isFileCached = true
            logger?.trace?.log(category: "ResourceRefresher",
                               message: "Resource \(id) saved in the cache: \(serializedResource)")
        } catch {
            logger?.error?.log(category: "ResourceRefresher",
                               message: "Failed to save downloaded resource \(id) due to error\n\(error)")
            _onRefreshError.publish(error)
        }
    }

    /**
     * Updates the refreshInterval to the specified seconds.
     *
     * - Parameters:
     *  - seconds: The amound of seconds to wait between refreshes.
     */
    public func setRefreshInterval(_ seconds: Double) {
        parameters.refreshInterval = seconds
        errorCooldown?.maxInterval = seconds
    }

    deinit {
        disposableRequest?.dispose()
    }
}
