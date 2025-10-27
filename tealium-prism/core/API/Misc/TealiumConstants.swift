//
//  TealiumConstants.swift
//  tealium-prism
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import UIKit
// MARK: VALUES
#endif

public enum TealiumConstants {
    public static let libraryName = "prism-swift"
    public static let libraryVersion = "0.1.0"
    public static let unknown = "unknown"

    static let tiqCdn = "https://tags.tiqcdn.com"

    static let killVisitorSessionQueryParam = "kill_visitor_session"
    static let leaveTraceQueryParam = "leave_trace"
    static let traceIdQueryParam = "tealium_trace_id"
    static let deepLinkEvent = "deep_link"
}

public enum TealiumDataKey {
}

public extension TealiumDataKey {
    static let account = "tealium_account"
    static let profile = "tealium_profile"
    static let environment = "tealium_environment"
    static let visitorId = "tealium_visitor_id"
    static let event = "tealium_event"
    static let screenTitle = "screen_title"
    static let eventType = "tealium_event_type"
    static let libraryName = "tealium_library_name"
    static let libraryVersion = "tealium_library_version"
    static let dataSource = "tealium_datasource"
    /// An `Int64` value containing the time, measured in seconds, since midnight 01-01-1970, in which the session was started.
    static let sessionId = "tealium_session_id"
    /// A `Boolean` value of `true` to indicate that this event was the first event of a new session.
    static let isNewSession = "is_new_session"
    /// An `Int64` value containing the session timeout measured in milliseconds.
    static let sessionTimeout = "_dc_ttl_"
    static let random = "tealium_random"
    static let enabledModules = "enabled_modules"
    static let enabledModulesVersions = "enabled_modules_versions"
    static let deepLinkURL = "deep_link_url"
    static let deepLinkQueryPrefix = "deep_link_param"
    static let deepLinkReferrerUrl = "deep_link_referrer_url"
    static let deepLinkReferrerApp = "deep_link_referrer_app"
    static let killVisitorSessionEvent = "event"
    static let traceId = "cp.trace_id"
}

public enum HttpStatusCodes: Int {
    case notModified = 304
    case ok = 200 // swiftlint:disable:this identifier_name
}

enum ConditionOperators {
    static let equals = "equals"
    static let equalsIgnoreCase = "equals_ignore_case"
    static let startsWith = "starts_with"
    static let startsWithIgnoreCase = "starts_with_ignore_case"
    static let doesNotStartWith = "does_not_start_with"
    static let doesNotStartWithIgnoreCase = "does_not_start_with_ignore_case"
    static let doesNotEqual = "does_not_equal"
    static let doesNotEqualIgnoreCase = "does_not_equal_ignore_case"
    static let endsWith = "ends_with"
    static let endsWithIgnoreCase = "ends_with_ignore_case"
    static let doesNotEndWith = "does_not_end_with"
    static let doesNotEndWithIgnoreCase = "does_not_end_with_ignore_case"
    static let contains = "contains"
    static let containsIgnoreCase = "contains_ignore_case"
    static let doesNotContain = "does_not_contain"
    static let doesNotContainIgnoreCase = "does_not_contain_ignore_case"
    static let defined = "defined"
    static let notDefined = "notdefined"
    static let empty = "empty"
    static let notEmpty = "notempty"
    static let greaterThan = "greater_than"
    static let greaterThanEqualTo = "greater_than_equal_to"
    static let lessThan = "less_than"
    static let lessThanEqualTo = "less_than_equal_to"
    static let regularExpression = "regular_expression"
}

enum Transformers {
    static let jsonTransformer = "JsonTransformer"
}
