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
    let resourceCacher: ResourceCacher<Resource>
    private var parameters: RefreshParameters
    public var id: String {
        parameters.id
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
    private let logger: LoggerProtocol

    @ToAnyObservable<BasePublisher<Resource>>(BasePublisher())
    var onResourceLoaded: Observable<Resource>

    /// An observable sequence of resources, starting from whatever might be cached on disk, and followed with all the subsequent successful refreshes.
    public var onLatestResource: Observable<Resource> {
        Observable.Just(readResource())
            .compactMap { $0 }
            .merge(_onResourceLoaded.asObservable())
    }

    /**
     * An observable sequence of errors that might come from network or from failing to write the cached resource on disk.
     *
     * Note that 304 errors are ignored as they are the intended network response when the resource was not modified.
     */
    @ToAnyObservable<BasePublisher<Error>>(BasePublisher<Error>())
    public var onRefreshError: Observable<Error>

    private var disposableRequest: Disposable?

    public init(networkHelper: NetworkHelperProtocol,
                resourceCacher: ResourceCacher<Resource>,
                parameters: RefreshParameters,
                errorCooldown: ErrorCooldown? = nil,
                logger: LoggerProtocol) {
        self.networkHelper = networkHelper
        self.resourceCacher = resourceCacher
        self.parameters = parameters
        self.errorCooldown = errorCooldown ?? ErrorCooldown(baseInterval: parameters.errorCooldownBaseInterval,
                                                            maxInterval: parameters.refreshInterval)
        self.logger = logger
        if lastEtag == nil && isFileCached {
            lastEtag = resourceCacher.readEtag()
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
                    self.logger.debug(category: LogCategory.resourceRefresher,
                                      "Refreshed resource \(id)")
                    self.saveResource(response.object, etag: response.urlResponse.etag)
                    self._onResourceLoaded.publish(response.object)
                } else {
                    self.logger.debug(category: LogCategory.resourceRefresher,
                                      "Downloaded resource \(id) but discarded as not valid")
                }
                self.errorCooldown?.newCooldownEvent(error: nil)
            case .failure(let error):
                if case let .non200Status(code) = error, code == 304 {
                    self.logger.trace(category: LogCategory.resourceRefresher,
                                      "Resource \(id) is not modified")
                    self.errorCooldown?.newCooldownEvent(error: nil)
                } else {
                    self.logger.error(category: LogCategory.resourceRefresher,
                                      "Failed to refresh resource \(id).\nError: \(error)")
                    self._onRefreshError.publish(error)
                    self.errorCooldown?.newCooldownEvent(error: error)
                }
            }
            self.lastFetch = Date()
            self.disposableRequest = nil
        }
    }

    private func readResource() -> Resource? {
        let resource = resourceCacher.readResource()
        isFileCached = resource != nil
        return resource
    }

    private func saveResource(_ resource: Resource, etag: String?) {
        let id = self.id
        do {
            try resourceCacher.saveResource(resource, etag: etag)
            lastEtag = etag
            isFileCached = true
            logger.trace(category: LogCategory.resourceRefresher,
                         "Resource \(id) saved in the cache:\n\(resource)")
        } catch {
            logger.error(category: LogCategory.resourceRefresher,
                         "Failed to save downloaded resource \(id).\nError: \(error)")
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
