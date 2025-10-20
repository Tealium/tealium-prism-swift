//
//  SessionManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Handles the starting and stopping of sessions, as well as expiration of session-scoped data.
 *
 * Sessions are tied explicitly to events. They are started and extended only by events registered
 * via `registerDispatch`.
 * On subsequent launches, if a session is still active, it will be resumed and extended to the current `sessionTimeout`.
 *
 * They are expired eagerly when no new events have been received, where the previous event is older
 * than the given `sessionTimeout`. Or during initialization, if the previous session has expired.
 */
class SessionManager: SessionRegistry {

    @ReplaySubject<Session> var session
    let sessionTimeout: ObservableState<TimeFrame>
    let dataStore: DataStore
    let logger: LoggerProtocol?
    let disposer = AutomaticDisposer()
    let debouncer: DebouncerProtocol
    init(debouncer: DebouncerProtocol,
         dataStore: DataStore,
         moduleRepository: ModulesRepository,
         sessionTimeout: ObservableState<TimeFrame>,
         timestamp: Int64 = Date().unixTimeMilliseconds,
         logger: LoggerProtocol?) {
        self.dataStore = dataStore
        self.sessionTimeout = sessionTimeout.mapState(transform: { timeFrame in
            timeFrame.coerce(min: 5.seconds, max: 30.minutes)
        })
        self.logger = logger
        self.debouncer = debouncer

        if let logger {
            session.distinct(isEqual: { $0.sessionId == $1.sessionId && $0.status == $1.status })
                .subscribe { newSession in
                    logger.debug(category: LogCategory.sessionManager,
                                 "Session \(newSession.status): \(newSession.sessionId)")
                }.addTo(disposer)
        }
        session.subscribe { [weak self] newSession in
            guard newSession.status != .ended else {
                moduleRepository.deleteExpired(expiry: .sessionChange)
                return
            }
            self?.storeSession(newSession)
            self?.restartExpirationTimer(timestamp: newSession.lastEventTimeMilliseconds)
        }.addTo(disposer)
        guard let info = dataStore.readSession() else {
            // It's possible that a session ended, and session-scoped data was subsequently added
            // without a current session. In that case, we delete the session-scoped data on init.
            moduleRepository.deleteExpired(expiry: .sessionChange)
            return
        }
        let sessionStatus = if info.isExpired(currentTimeMilliseconds: timestamp,
                                              sessionTimeout: self.sessionTimeout.value) {
            Session.Status.ended
        } else {
            Session.Status.resumed
        }
        _session.publish(Session(status: sessionStatus, sessionInfo: info))
    }

    func restartExpirationTimer(timestamp: Int64) {
        let expirationTime = Double(timestamp / 1000) + sessionTimeout.value.inSeconds()
        let now = Date().timeIntervalSince1970
        let delay = expirationTime - now
        debouncer.debounce(time: delay) { [weak self] in
            guard let session = self?._session,
                  let currentSession = session.last(),
                  timestamp == currentSession.lastEventTimeMilliseconds else {
                return
            }
            let expiredSession = Session(status: .ended, sessionInfo: currentSession.info)
            session.publish(expiredSession)
        }
    }

    func registerDispatch(_ dispatch: inout Dispatch) {
        let timestamp = dispatch.timestamp
        let newSession = createOrExtendSession(timestamp: timestamp)
        var sessionData: DataObject = [
            TealiumDataKey.sessionId: newSession.sessionId,
            TealiumDataKey.sessionTimeout: sessionTimeout.value.inMilliseconds()
        ]
        if newSession.eventCount <= 1 {
            sessionData.set(true, key: TealiumDataKey.isNewSession)
        }
        dispatch.enrich(data: sessionData)
        _session.publish(newSession)
    }

    func storeSession(_ session: Session) {
        do {
            try dataStore.putSession(session.info)
        } catch {
            logger?.error(category: LogCategory.sessionManager, "Error writing session data\n\(error)")
        }
    }

    func createOrExtendSession(timestamp: Int64) -> Session {
        if let session = _session.last(), session.status != .ended {
            session.incrementAndExtend(timestamp: timestamp)
        } else {
            Session(status: .started, sessionInfo: .new(timestamp: timestamp))
        }
    }
}

fileprivate extension DataStore {
    private static var sessionInfoKey: String { "session_info" }
    func readSession() -> SessionInfo? {
        getConvertible(key: Self.sessionInfoKey, converter: SessionInfo.converter)
    }

    func putSession(_ session: SessionInfo) throws {
        try edit()
            .put(key: Self.sessionInfoKey,
                 value: session.toDataInput(),
                 expiry: .session)
            .commit()
    }
}
