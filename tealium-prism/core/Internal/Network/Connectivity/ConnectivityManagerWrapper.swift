//
//  ConnectivityManagerWrapper.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A Wrapper that subscribes on the manager's queue, but emits events from a potentially different queue.
 *
 * In most instances, this class would do nothing as the two queues should be the same, but in tests these queues might differ for ease of use.
 */
class ConnectivityManagerWrapper: ConnectivityManagerProtocol {

    @StateSubject(true)
    var connectionAssumedAvailable: ObservableState<Bool>

    @StateSubject(NetworkConnection.unknown)
    var connection: ObservableState<NetworkConnection>

    let disposable: any CompositeDisposable

    init(connectivityManager: ConnectivityManager, queue: TealiumQueue) {
        disposable = Disposables.composite(queue: connectivityManager.queue)
        // Note that we can't use `observeOn` here because we `subscribeOn` a different queue.
        // If we did use `observeOn` we would be causing race conditions.
        connectivityManager.connectionAssumedAvailable
            .subscribeOn(connectivityManager.queue)
            .subscribe { [weak self] element in
                queue.ensureOnQueue {
                    self?._connectionAssumedAvailable.onNextIfChanged(element)
                }
            }.addTo(disposable)
        connectivityManager.connection
            .subscribeOn(connectivityManager.queue)
            .subscribe { [weak self] element in
                queue.ensureOnQueue {
                    self?._connection.onNextIfChanged(element)
                }
            }.addTo(disposable)
    }

    deinit {
        disposable.dispose()
    }
}
