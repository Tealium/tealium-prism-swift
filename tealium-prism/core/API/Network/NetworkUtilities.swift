//
//  NetworkUtilities.swift
//  tealium-prism
//
//  Created by Denis Guzov on 19/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// Groups the networking utilities for a given `Tealium` instance onto a single object.
public final class NetworkUtilities {
    /// Helper for standard, uncompressed network operations.
    public let networkHelper: NetworkHelperProtocol
    /// The network client for sending requests — the entry point for custom (e.g. gzipped) requests
    /// built with a `RequestBuilder` or a `URLRequest`.
    public let networkClient: NetworkClient
    /// Underlying connectivity manager. Also exposes the empirical-connectivity layer used
    /// internally by barriers and the retry interceptor.
    public let connectivityManager: ConnectivityManagerProtocol

    init(networkHelper: NetworkHelperProtocol,
         networkClient: NetworkClient,
         connectivityManager: ConnectivityManagerProtocol) {
        self.networkHelper = networkHelper
        self.networkClient = networkClient
        self.connectivityManager = connectivityManager
    }
}
