//
//  NetworkUtilities.swift
//  tealium-prism
//
//  Created by Denis Guzov on 19/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Groups the networking utilities for a given `Tealium` instance onto a single object.
 *
 * `networkClient` and `networkHelper` make a single attempt for each request and never retry it.
 * Every response still feeds the empirical connectivity of the `connectivityManager`.
 *
 * To retry failed requests, derive a client with `NetworkClient.newClient(withAdditionalInterceptors:)`,
 * adding `RequestInterceptors.retryWithBackoff()` to retry retryable failures with a backoff and/or
 * `RequestInterceptors.retryWhenConnected(connectivityManager:)` to wait for connectivity to return before retrying.
 * Use `NetworkClient.makeNetworkHelper()` to send requests through the derived client with the `NetworkHelperProtocol` API.
 */
public final class NetworkUtilities {
    /// Helper for standard, uncompressed network operations.
    public let networkHelper: NetworkHelperProtocol
    /// The network client for sending requests — the entry point for custom (e.g. gzipped) requests
    /// built with a `RequestBuilder` or a `URLRequest`.
    public let networkClient: NetworkClient
    /// Whether the connection is assumed available (`connectionAssumedAvailable`) and the system connection state (`connection`).
    public let connectivityManager: ConnectivityManagerProtocol

    init(networkHelper: NetworkHelperProtocol,
         networkClient: NetworkClient,
         connectivityManager: ConnectivityManagerProtocol) {
        self.networkHelper = networkHelper
        self.networkClient = networkClient
        self.connectivityManager = connectivityManager
    }
}
