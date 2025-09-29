//
//  MockBundle.swift
//  tealium-prism
//
//  Created by Den Guzov on 30/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

class MockBundle: Bundle, @unchecked Sendable {
    private let mockInfoDictionary: [String: Any]

    init(infoDictionary: [String: Any]) {
        self.mockInfoDictionary = infoDictionary
        super.init()
    }

    override var infoDictionary: [String: Any]? {
        return mockInfoDictionary
    }

    override var bundleIdentifier: String? {
        return mockInfoDictionary["CFBundleIdentifier"] as? String
    }
}
