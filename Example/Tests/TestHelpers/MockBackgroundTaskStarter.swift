//
//  MockBackgroundTaskStarter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/03/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

class MockBackgroundTaskStarter: BackgroundTaskStarter {

    // This Subject assumes only one task running at the time.
    @StateSubject<Bool>(false)
    var onBackgroundTaskStarted

    var backgroundTaskOngoing: Bool {
        _onBackgroundTaskStarted.value
    }

    override func startBackgroundTask(withName name: String? = nil) -> Observable<Bool> {
        Observable<Bool> { [_onBackgroundTaskStarted] observer in
            _onBackgroundTaskStarted.publishIfChanged(false)
            return super.startBackgroundTask(withName: name)
                .subscribe { ongoing in
                    _onBackgroundTaskStarted.publishIfChanged(ongoing)
                    observer(ongoing)
                }
                .onDispose {
                    _onBackgroundTaskStarted.publishIfChanged(false)
                }
        }
    }
}
