//
//  String.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//
import CommonCrypto
import Foundation

extension Data {
    func sha256() -> String {
        hexStringFromData(input: digest(input: self as NSData))
    }

    private func digest(input: NSData) -> [UInt8] {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return hash
    }

    private func hexStringFromData(input: [UInt8]) -> String {
        input.map { String(format: "%02x", $0) }
            .joined()
    }
}

extension String {
    // Not to be used with unbounded strings like large files or similar
    func sha256() -> String? {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return nil
    }
}
