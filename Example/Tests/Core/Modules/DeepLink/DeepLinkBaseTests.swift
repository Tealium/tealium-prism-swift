//
//  DeepLinkBaseTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class DeepLinkBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    let manager = ModuleManager()
    lazy var onManager = ReplaySubject<ModuleManager?>(manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = TraceWrapper(moduleProxy: ModuleProxy(queue: queue,
                                                             onModuleManager: onManager.asObservable()))

    func context() -> TealiumContext {
        MockContext(moduleManager: manager,
                    config: config,
                    tracker: tracker,
                    databaseProvider: dbProvider,
                    queue: queue)
    }
    var deepLink: DeepLinkModule!
    let dispatchContext = DispatchContext(source: .application, initialData: [:])
    let testTraceId = "testTraceId"

    /// The Trace module held by the manager, which the deep link module resolves asynchronously.
    var trace: TraceModule? {
        manager.getModule()
    }

    /// The id of the trace currently joined, or `nil` when no trace is active.
    var joinedTraceId: String? {
        trace?.collect(dispatchContext).get(key: TealiumDataKey.tealiumTraceId)
    }

    override func setUp() {
        config.modules = [Modules.trace()]
        let context = context()
        manager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        deepLink = makeDeepLink(context: context)
    }

    /// Creates the module through its factory, the only way it comes into existence in production.
    func makeDeepLink(context: TealiumContext,
                      configuration: DataObject = [:],
                      onOpenUrl: Observable<(URL, Referrer?)>? = nil) -> DeepLinkModule? {
        DeepLinkModuleFactory(enforcedSettings: nil, onOpenUrl: onOpenUrl)
            .create(moduleId: DeepLinkModule.moduleType, context: context, moduleConfiguration: configuration)
    }

    /**
     * Handles the link and waits for the handling to complete.
     *
     * Handling a link that requests a trace is asynchronous: it resolves the Trace module through
     * `ModuleManager.observeModule`, which only answers once a modules pass has run.
     */
    func handleAndWait(link: URL,
                       referrer: Referrer? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        let handled = expectation(description: "Deep link handled")
        deepLink.handle(link: link, referrer: referrer) { result in
            XCTAssertResultIsSuccess(result, file: file, line: line)
            handled.fulfill()
        }
        wait(for: [handled], timeout: Self.defaultTimeout)
    }

    func updateSettings(_ builder: DeepLinkSettingsBuilder) {
        let configuration = builder.build()
            .getDataDictionary(key: "configuration")?.toDataObject() ?? [:]
        _ = deepLink.updateConfiguration(configuration)
    }
}
