//
//  MockMatchable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 05/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

struct MockMatchable: Matchable {
    let result: Bool
    @ToAnyObservable<BasePublisher<DataObject>>(BasePublisher())
    var onMatchRequest: Observable<DataObject>
    func matches(payload: DataObject) -> Bool {
        _onMatchRequest.publish(payload)
        return result
    }
}
