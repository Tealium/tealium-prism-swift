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

/// Constants used throughout the Tealium SDK.
public enum TealiumConstants {
    /// The name of this Tealium library.
    public static let libraryName = "prism-swift"
    /// The version of this Tealium library.
    public static let libraryVersion = "0.1.0"
    /// A constant representing an unknown value as a string.
    public static let unknown = "unknown"

    static let tiqCdn = "https://tags.tiqcdn.com"

    static let forceEndOfVisitQueryParam = "kill_visitor_session"
    static let leaveTraceQueryParam = "leave_trace"
    static let deepLinkEvent = "deep_link"
}

/// Keys used for data in Tealium tracking events.
public enum TealiumDataKey {
}

/// Extension containing standard Tealium data keys.
public extension TealiumDataKey {
    /// The Tealium account identifier.
    static let account = "tealium_account"
    /// The Tealium profile identifier.
    static let profile = "tealium_profile"
    /// The Tealium environment (dev, qa, prod).
    static let environment = "tealium_environment"
    /// The unique visitor identifier.
    static let visitorId = "tealium_visitor_id"
    /// The event name.
    static let event = "tealium_event"
    /// The screen or page title.
    static let screenTitle = "screen_title"
    /// The type of event (view, event).
    static let eventType = "tealium_event_type"
    /// The name of the Tealium library.
    static let libraryName = "tealium_library_name"
    /// The version of the Tealium library.
    static let libraryVersion = "tealium_library_version"
    /// The data source identifier.
    static let dataSource = "tealium_datasource"
    /// An `Int64` value containing the time, measured in seconds, since midnight 01-01-1970, in which the session was started.
    static let sessionId = "tealium_session_id"
    /// A `Boolean` value of `true` to indicate that this event was the first event of a new session.
    static let isNewSession = "is_new_session"
    /// An `Int64` value containing the session timeout measured in milliseconds.
    static let sessionTimeout = "_dc_ttl_"
    /// A random value for unique event identification and deduplication.
    static let random = "tealium_random"
    /// List of enabled modules.
    static let enabledModules = "enabled_modules"
    /// Versions of enabled modules.
    static let enabledModulesVersions = "enabled_modules_versions"
    /// The URL from a deep link.
    static let deepLinkURL = "deep_link_url"
    /// Prefix for deep link query parameters.
    static let deepLinkQueryPrefix = "deep_link_param"
    /// The referrer URL for a deep link.
    static let deepLinkReferrerUrl = "deep_link_referrer_url"
    /// The referrer app for a deep link.
    static let deepLinkReferrerApp = "deep_link_referrer_app"
    /// The trace ID for debugging. The same value will be keyed by `tealium_trace_id` (see `tealiumTraceId` key).
    /// Both keys should be kept and their associated values should be in sync. (see `Trace`)
    static let cpTraceId = "cp.trace_id"
    /// The trace ID for debugging. The same value will be keyed by `cp.trace_id` (see `cpTraceId` key).
    /// Both keys should be kept and their associated values should be in sync. (see `Trace`)
    static let tealiumTraceId = "tealium_trace_id"
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
