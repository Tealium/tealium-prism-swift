//
//  Version1VisitorFixture.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 12/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// Rows for `stageVersion1Database(rows:)`: the visitor data and neighbours as 0.6.0 left them in the `shared` module.
///
/// Rows have 0.6.0-shaped values: JSON-quoted strings and `expiry = -1` (`.forever`).
/// Keys mirror `VisitorStorage.Keys` at tag `0.6.0` (`visitorId`, `currentIdentity`), where each association was stored
/// under the SHA-256 of its identity, as lower-case hex produced by `String.sha256()`.
enum Version1VisitorFixture {
    typealias Row = XCTestCase.StoredRow

    static let sharedModule = "shared"

    static let hashA = Data("identity-a".utf8).sha256()
    static let hashB = Data("identity-b".utf8).sha256()
    static let hashC = Data("identity-c".utf8).sha256()

    static let currentVisitorId = "visitor-id-current"
    static let olderVisitorIdB = "visitor-id-b"
    static let olderVisitorIdC = "visitor-id-c"

    /// Full visitor state: `VisitorStorage.Keys.visitorId`, `.currentIdentity` (the hash of identity A) and one
    /// association per identity. A's association is the current visitor id, B's and C's are older ones.
    static let visitorState: [Row] = [
        row("visitorId", "\"\(currentVisitorId)\""),
        row("currentIdentity", "\"\(hashA)\""),
        row(hashA, "\"\(currentVisitorId)\""),
        // A real expiry timestamp in milliseconds (`.after(Date)`), unlike the -1 of `.forever`, to prove the move leaves it alone.
        row(hashB, "\"\(olderVisitorIdB)\"", expiry: 1_900_000_000_000),
        row(hashC, "\"\(olderVisitorIdC)\"")
    ]

    /// Rows of other writers of the shared store: `ResourceCacher`'s cache of the settings (`SettingsManager` uses the
    /// file name `settings`, which holds the serialized settings as a string) and `SessionManager`'s `session_info`.
    static let otherSharedRows: [Row] = [
        row("settings", "\"{\\\"core\\\":{\\\"account\\\":\\\"a\\\"}}\""),
        row("session_info", "{\"sessionId\":123,\"status\":1}")
    ]

    /// Rows that resemble associations but are not: an upper-case 64-hex key, a 64-character key that isn't hex,
    /// a 64-hex key whose value is not a JSON string, lower-case hex keys that aren't 64 characters, and a 64-hex
    /// key whose value is a lone quote.
    static let lookAlikes: [Row] = [
        row(String(repeating: "A", count: 64), "\"upper-case\""),
        row(String(repeating: "g", count: 64), "\"not-hex\""),
        row(String(repeating: "b", count: 64), "{\"a\":1}"),
        row("cafe", "\"short\""),
        row(String(repeating: "c", count: 63), "\"63\""),
        row(String(repeating: "d", count: 65), "\"65\""),
        row(String(repeating: "e", count: 64), "\"")
    ]

    /// The visitor state, the other shared rows and the look-alikes.
    static let all = visitorState + otherSharedRows + lookAlikes

    /// An anonymous install: a visitor id that no identity ever owned, and nothing else.
    static let anonymous = [row("visitorId", "\"\(currentVisitorId)\"")]

    /// Everything except the `visitorId` row: the association-shaped rows are there, but no visitor id was ever written.
    static let withoutVisitorId = all.filter { $0.key != "visitorId" }

    private static func row(_ key: String, _ value: String, expiry: Int64 = -1) -> Row {
        Row(module: sharedModule, key: key, value: value, expiry: expiry)
    }
}
