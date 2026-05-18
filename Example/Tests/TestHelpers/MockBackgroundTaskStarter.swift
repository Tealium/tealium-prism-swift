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
        Observables.create { [_onBackgroundTaskStarted] observer in
            _onBackgroundTaskStarted.onNextIfChanged(false)
            let composite = Disposables.composite().onDispose {
                _onBackgroundTaskStarted.onNextIfChanged(false)
            }
            super.startBackgroundTask(withName: name)
                .subscribe { ongoing in
                    _onBackgroundTaskStarted.onNextIfChanged(ongoing)
                    observer.onNext(ongoing)
                }.addTo(composite)
            return composite
        }
    }
}
