//
//  UIScene+DelegateGetter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

private let swizzling: (AnyClass, Selector, Selector) -> Void = { forClass, originalSelector, swizzledSelector in
    guard
        let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
    else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

@available(iOS 13.0, *)
extension UIScene {
    static let tealSwizzleDelegateGetterOnce: Void = {
        let originalSelector = #selector(getter: delegate)
        let swizzledSelector = #selector(getter: teal_swizzled_delegate)
        swizzling(UIScene.self, originalSelector, swizzledSelector)
    }()

    static var onDelegateGetterBlock: ((UISceneDelegate?) -> Void)?

    @objc private var teal_swizzled_delegate: UISceneDelegate? {
        // self.teal_swizzled_delegate would actually be the original implementation (self.delegate) after swizzling
        let delegate = self.teal_swizzled_delegate
        TealiumQueue.main.ensureOnQueue {
            UIScene.onDelegateGetterBlock?(delegate)
        }
        return delegate
    }
}

#endif
