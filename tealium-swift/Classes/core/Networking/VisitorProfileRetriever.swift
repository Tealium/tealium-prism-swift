//
//  VisitorProfileRetriever.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/04/23.
//

import Foundation

struct VisitorProfile: Codable {
    let eventsCount: Int?
}

typealias VisitorProfileResult = Result<VisitorProfile?, NetworkError>

extension VisitorProfileResult {
    func shouldRetry(currentCount: Int) -> Bool {
        switch self {
        case .success(let profile):
            guard let count = profile?.eventsCount else {
                return true
            }
            return count <= currentCount
        case .failure:
            return false
        }
    }
}

/**
 * Just an example to POC the RetryManager
 */
class VisitorProfileRetriever {
    var retrivingProfile: TealiumDisposable?
    var cachedProfile: VisitorProfile?
    var currentVisitorId: String = ""
    
    public func getProfile(delayed: Bool) {
        retrivingProfile?.dispose()
        let getVisitorProfile: (String, Int, @escaping (VisitorProfileResult) -> Void) -> TealiumDisposable
        if delayed {
            getVisitorProfile = delayedGetVisitorProfile(visitorId:retryCount:completion:)
        } else {
            getVisitorProfile = retryableGetVisitorProfile(visitorId:retryCount:completion:)
        }
        retrivingProfile = getVisitorProfile(currentVisitorId, 0) { result in
            if let profile = try? result.get() {
                self.cachedProfile = profile
            }
        }
    }
    
    private func delayedGetVisitorProfile(visitorId: String, retryCount: Int = 0, completion: @escaping (VisitorProfileResult) -> Void) -> TealiumDisposable {
        let completion = SelfDestructingCompletion(completion: completion)
        let disposeContainer = TealiumDisposeContainer()
        tealiumQueue.asyncAfter(deadline: .now() + 2.1) {
            guard !disposeContainer.isDisposed, visitorId == self.currentVisitorId else {
                completion.fail(error: .cancelled)
                return
            }
            self.retryableGetVisitorProfile(visitorId: visitorId,
                                            retryCount: retryCount,
                                            completion: completion.complete)
            .addTo(disposeContainer)
        }
        return TealiumSubscription {
                completion.fail(error: .cancelled)
                disposeContainer.dispose()
        }
    }
    
    private func retryableGetVisitorProfile(visitorId: String, retryCount: Int, completion: @escaping (VisitorProfileResult) -> Void) -> TealiumDisposable {
        let disposeContainer = TealiumDisposeContainer()
        _getVisitorProfile(visitorId: visitorId) { result in
            guard !disposeContainer.isDisposed, visitorId == self.currentVisitorId else {
                completion(.failure(.cancelled))
                return
            }
            if result.shouldRetry(currentCount: retryCount) {
                self.delayedGetVisitorProfile(visitorId: visitorId,
                                              retryCount: retryCount+1,
                                              completion: completion)
                .addTo(disposeContainer)
            } else {
                completion(result)
            }
        }.addTo(disposeContainer)
        return disposeContainer
    }
    
    
    private func _getVisitorProfile(visitorId: String, completion: @escaping (VisitorProfileResult) -> Void) -> TealiumDisposable {
        NetworkClient.shared.sendRequest(URLRequest(url: URL(string: "")!)) { result in
            guard visitorId == self.currentVisitorId else {
                completion(.failure(.cancelled))
                return
            }
            completion(result.map({ response in
                try? JSONDecoder().decode(VisitorProfile.self, from: response.data)
            }))
        }
    }
}
