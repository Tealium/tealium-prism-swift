//
//  TealiumDelegateProxy.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//
// Based on  https://notificare.com/blog/2020/07/24/Swizzling-with-Swift/ 🙏

#if os(iOS)
import Foundation
import UIKit

@objc
public class TealiumDelegateProxy: NSProxy {
    class Configuration {
        private let bundle: Bundle

        init(bundle: Bundle = .main) {
            self.bundle = bundle
        }

        lazy var isAutotrackingDeepLinkEnabled: Bool =
            bundle.infoDictionary?["TealiumAutotrackingDeepLinkEnabled"] as? Bool ?? true
    }
    static var configuration: Configuration = .init()

    private struct AssociatedObjectKeys {
        // https://forums.swift.org/t/handling-the-new-forming-unsaferawpointer-warning/65523/7
        // swiftlint:disable force_unwrapping
        static let originalClass = malloc(1)!
        static let originalImplementations = malloc(1)!
        // swiftlint:enable force_unwrapping
    }

    static private(set) var sceneEnabled = false
    private static var name = "AppDelegate"

    private static let _onOpenUrl = ReplaySubject<(URL, Referrer?)>()

    /**
     * If autotracking of deep link is enabled it returns a subscribable to register on.
     *
     * The subscribable always emits on the `TealiumQueue.worker`.
     */
    public static var onOpenUrl: Observable<(URL, Referrer?)>? {
        guard configuration.isAutotrackingDeepLinkEnabled else {
            return nil
        }
        return _onOpenUrl.asObservable()
    }

    static let logger: LoggerProtocol = TealiumLogger(logHandler: OSLogger(),
                                                      onLogLevel: Observables.just(.info),
                                                      forceLevel: .info)
    @objc
    public static func setup() {
        guard configuration.isAutotrackingDeepLinkEnabled else {
            return
        }
        TealiumQueue.main.ensureOnQueue {
            _ = runOnce
        }
    }

    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        guard configuration.isAutotrackingDeepLinkEnabled else {
            return
        }
        UIScene.onDelegateGetterBlock = { delegate in
            UIScene.onDelegateGetterBlock = nil
            if let delegate = delegate {
                TealiumDelegateProxy.proxySceneDelegate(delegate)
            } else {
                TealiumDelegateProxy.proxyAppDelegate()
            }
        }
        _ = UIScene.tealSwizzleDelegateGetterOnce
    }()
}

// MARK: Swizzling

private extension TealiumDelegateProxy {

    typealias ApplicationOpenURL = @convention(c) (Any, Selector, UIApplication, URL, [UIApplication.OpenURLOptionsKey: Any]) -> Bool
    typealias ApplicationContinueUserActivity = @convention(c) (Any, Selector, UIApplication, NSUserActivity, @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    typealias SceneWillConnectTo = @convention(c) (Any, Selector, UIScene, UISceneSession, UIScene.ConnectionOptions) -> Void
    typealias SceneOpenURLContexts = @convention(c) (Any, Selector, UIScene, Set<UIOpenURLContext>) -> Void
    typealias SceneContinueUserActivity = @convention(c) (Any, Selector, UIScene, NSUserActivity) -> Void

    static let ApplicationOpenUrlSelector = #selector(application(_:openURL:options:))
    static let ApplicationContinueUserActivitySelector = #selector(application(_:continueUserActivity:restorationHandler:))
    static let SceneWillConnectToSelector = #selector(scene(_:willConnectToSession:options:))
    static let SceneOpenURLContextsSelector = #selector(scene(_:openURLContexts:))
    static let SceneContinueUserActivitySelector = #selector(scene(_:continueUserActivity:))

    static var gOriginalDelegate: NSObjectProtocol?
    static var gDelegateSubClass: AnyClass?

    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }

    static func proxySceneDelegate(_ sceneDelegate: UISceneDelegate) {
        sceneEnabled = true
        name = "SceneDelegate"
        proxyUIDelegate(sceneDelegate)
    }

    static func proxyAppDelegate() {
        let appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
        proxyUIDelegate(appDelegate)
    }

    static func proxyUIDelegate(_ uiDelegate: NSObjectProtocol?) {
        guard let uiDelegate = uiDelegate, gDelegateSubClass == nil else {
            log("Original \(TealiumDelegateProxy.name) instance was nil")
            return
        }

        gDelegateSubClass = createSubClass(from: uiDelegate)
        self.reassignDelegate()
    }

    // This is required otherwise if AppDelegate/SceneDelegate don't implement those methods it won't work!
    // Setting the delegate again probably causes the system to check again for the presence of those methods that were missing before.
    static func reassignDelegate() {
        if sceneEnabled {
            weak var sceneDelegate = TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate
            TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate = nil
            TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate = sceneDelegate
            gOriginalDelegate = sceneDelegate
        } else {
            weak var appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
            TealiumDelegateProxy.sharedApplication?.delegate = nil
            TealiumDelegateProxy.sharedApplication?.delegate = appDelegate
            gOriginalDelegate = appDelegate
        }
    }

    static func createSubClass(from originalDelegate: NSObjectProtocol) -> AnyClass? {
        let originalClass = type(of: originalDelegate)
        let newClassName = "\(originalClass)_\(UUID().uuidString)"

        guard NSClassFromString(newClassName) == nil else {
            return nil
        }

        guard let subClass = objc_allocateClassPair(originalClass, newClassName, 0) else {
            return nil
        }

        self.createMethodImplementations(in: subClass, withOriginalDelegate: originalDelegate)
        self.overrideDescription(in: subClass)

        // Store the original class
        objc_setAssociatedObject(originalDelegate, AssociatedObjectKeys.originalClass, originalClass, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        guard class_getInstanceSize(originalClass) == class_getInstanceSize(subClass) else {
            return nil
        }

        objc_registerClassPair(subClass)
        if object_setClass(originalDelegate, subClass) != nil {
            log("Successfully created \(TealiumDelegateProxy.name) proxy")
        }

        return subClass
    }

    static func createMethodImplementations(
        in subClass: AnyClass,
        withOriginalDelegate originalDelegate: NSObjectProtocol
    ) {
        let originalClass = type(of: originalDelegate)
        var originalImplementationsStore: [String: NSValue] = [:]

        if sceneEnabled {
            let sceneOpenURLContexts = SceneOpenURLContextsSelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneOpenURLContexts,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneOpenURLContexts,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)

            let sceneContinueUserActivity = SceneContinueUserActivitySelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneContinueUserActivity,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneContinueUserActivity,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            let sceneWillConnectTo = SceneWillConnectToSelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneWillConnectTo,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneWillConnectTo,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
        } else {
            let applicationOpenURL = ApplicationOpenUrlSelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: applicationOpenURL,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: applicationOpenURL,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)

            let applicationContinueUserActivity = ApplicationContinueUserActivitySelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: applicationContinueUserActivity,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: applicationContinueUserActivity,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
        }

        // Store original implementations
        objc_setAssociatedObject(originalDelegate, AssociatedObjectKeys.originalImplementations, originalImplementationsStore, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static func overrideDescription(in subClass: AnyClass) {
        // Override the description so the custom class name will not show up.
        self.addInstanceMethod(
            toClass: subClass,
            toSelector: #selector(description),
            fromClass: TealiumDelegateProxy.self,
            fromSelector: #selector(originalDescription))
    }
    // swiftlint:disable function_parameter_count
    static func proxyInstanceMethod(
        toClass destinationClass: AnyClass,
        withSelector destinationSelector: Selector,
        fromClass sourceClass: AnyClass,
        fromSelector sourceSelector: Selector,
        withOriginalClass originalClass: AnyClass,
        storeOriginalImplementationInto originalImplementationsStore: inout [String: NSValue]
    ) {
        self.addInstanceMethod(
            toClass: destinationClass,
            toSelector: destinationSelector,
            fromClass: sourceClass,
            fromSelector: sourceSelector)

        let sourceImplementation = methodImplementation(for: destinationSelector, from: originalClass)
        let sourceImplementationPointer = NSValue(pointer: UnsafePointer(sourceImplementation))

        let destinationSelectorStr = NSStringFromSelector(destinationSelector)
        originalImplementationsStore[destinationSelectorStr] = sourceImplementationPointer
    }
    // swiftlint:enable function_parameter_count
    static func addInstanceMethod(
        toClass destinationClass: AnyClass,
        toSelector destinationSelector: Selector,
        fromClass sourceClass: AnyClass,
        fromSelector sourceSelector: Selector
    ) {
        guard let method = class_getInstanceMethod(sourceClass, sourceSelector) else {
            log("Cannot get instance method")
            return
        }
        let methodImplementation = method_getImplementation(method)
        let methodTypeEncoding = method_getTypeEncoding(method)
        if !class_addMethod(destinationClass, destinationSelector, methodImplementation, methodTypeEncoding) {
            log("Cannot copy method to destination selector '\(destinationSelector)' as it already exists.")
        }
    }

    static func methodImplementation(for selector: Selector, from fromClass: AnyClass) -> IMP? {
        guard let method = class_getInstanceMethod(fromClass, selector) else {
            return nil
        }
        return method_getImplementation(method)
    }

    static func originalMethodImplementation(for selector: Selector, object: Any) -> NSValue? {
        let originalImplementationsStore = objc_getAssociatedObject(object, AssociatedObjectKeys.originalImplementations) as? [String: NSValue]
        return originalImplementationsStore?[NSStringFromSelector(selector)]
    }
}

// MARK: App Delegate

private extension TealiumDelegateProxy {
    @objc
    func application(_ app: UIApplication, openURL url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        TealiumDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
        let referrer = Referrer.fromAppId(options[.sourceApplication] as? String)
        TealiumDelegateProxy.handleDeepLink(url, referrer: referrer)
        let methodSelector = TealiumDelegateProxy.ApplicationOpenUrlSelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  // return false to avoid consuming the URL - we never want to prevent the event from being consumed elsewhere
                  return false
              }
        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationOpenURL.self)
        let originalResult = originalImplementation(self, methodSelector, app, url, options)
        return originalResult
    }

    @objc
    func application(_ application: UIApplication,
                     continueUserActivity userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        handleContinueUserActivity(userActivity)

        let methodSelector = TealiumDelegateProxy.ApplicationContinueUserActivitySelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return false
              }
        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationContinueUserActivity.self)
        let originalResult = originalImplementation(self, methodSelector, application, userActivity, restorationHandler)
        return originalResult
    }

    @objc
    func originalDescription() -> String {
        if let originalClass = objc_getAssociatedObject(self, AssociatedObjectKeys.originalClass) as? AnyClass {
            let originalClassName = NSStringFromClass(originalClass)
            let pointerHex = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return "<\(originalClassName): \(pointerHex)>"
        }
        return "AppDelegate"
    }
}

// MARK: Scene Delegate

private extension TealiumDelegateProxy {

    @objc
    func scene(_ scene: UIScene,
               willConnectToSession session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let activity = connectionOptions.userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb }) {
            handleContinueUserActivity(activity)
        } else {
            handleUrlContexts(connectionOptions.urlContexts)
        }
        let methodSelector = TealiumDelegateProxy.SceneWillConnectToSelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return
              }

        let originalImplementation = unsafeBitCast(pointerValue, to: SceneWillConnectTo.self)
        originalImplementation(self, methodSelector, scene, session, connectionOptions)
    }

    @objc
    func scene(_ scene: UIScene, continueUserActivity: NSUserActivity) {
        handleContinueUserActivity(continueUserActivity)
        let methodSelector = TealiumDelegateProxy.SceneContinueUserActivitySelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return
              }

        let originalImplementation = unsafeBitCast(pointerValue, to: SceneContinueUserActivity.self)
        _ = originalImplementation(self, methodSelector, scene, continueUserActivity)
    }

    @objc
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleUrlContexts(URLContexts)
        let methodSelector = TealiumDelegateProxy.SceneOpenURLContextsSelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return
              }
        let originalImplementation = unsafeBitCast(pointerValue, to: SceneOpenURLContexts.self)
        originalImplementation(self, methodSelector, scene, URLContexts)
    }

    func handleUrlContexts(_ urlContexts: Set<UIOpenURLContext>) {
        urlContexts.forEach { urlContext in
            TealiumDelegateProxy.log("Received Deep Link: \(urlContext.url.absoluteString)")
            let referrer = Referrer.fromAppId(urlContext.options.sourceApplication)
            TealiumDelegateProxy.handleDeepLink(urlContext.url, referrer: referrer)
        }
    }
}

// MARK: Utils

private extension TealiumDelegateProxy {
    func handleContinueUserActivity(_ userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            TealiumDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
            let referrer = Referrer.fromUrl(userActivity.referrerURL)
            TealiumDelegateProxy.handleDeepLink(url, referrer: referrer)
        }
    }

    /// Handles log messages from the App or SceneDelegate proxy
    /// - Parameter message: `String` containing the message to be logged
    static func log(_ message: String) {
        logger.log(level: .info, category: "TealiumDelegateProxy", message)
    }

    /// Forwards deep link to each registered Tealium instance
    /// - Parameter url: `URL` of the deep link to be handled
    static func handleDeepLink(_ url: URL, referrer: Referrer? = nil) {
        TealiumQueue.worker.ensureOnQueue {
            _onOpenUrl.publish((url, referrer))
        }
    }
}

#endif
