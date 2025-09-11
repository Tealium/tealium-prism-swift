//
//  TealiumConstants.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import UIKit
// MARK: VALUES
#endif

public enum TealiumConstants {
    public static let libraryName = "swift"
    public static let libraryVersion = "3.0.0"
    // This is the current limit for performance reasons. May be increased in future
    public static let maxEventBatchSize = 10
    public static let defaultMinimumDiskSpace: Int32 = 20_000_000
    public static let tiqBaseURL = "https://tags.tiqcdn.com/utag/"
    public static let tiqURLSuffix = "mobile.html?sdk_session_count=true"
    public static let defaultBatchExpirationDays = 7
    public static let defaultMaxQueueSize = 40
//    static let defaultLoggerType: TealiumLoggerType = .os
    static let connectionRestoredReason = "Connection Restored"
    static let hdlMaxRetries = 3
    static let hdlCacheSizeMax = 50
//    static let defaultHDLExpiry: (Int, unit: TimeUnit) = (7, unit: .days)
    static let mobile = "mobile"
    public static let unknown = "unknown"
    public static let timedEvent = "timed_event"
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
    static let queueReason = "queue_reason"
    static let wasQueued = "was_queued"
    static let dispatchService = "dispatch_service"
    static let dataSource = "tealium_datasource"
    /// An `Int64` value containing the time, measured in seconds, since midnight 01-01-1970, in which the session was started.
    static let sessionId = "tealium_session_id"
    /// A `Boolean` value of `true` to indicate that this event was the first event of a new session.
    static let isNewSession = "is_new_session"
    /// An `Int64` value containing the session timeout measured in milliseconds.
    static let sessionTimeout = "_dc_ttl_"
    static let random = "tealium_random"
    static let uuid = "app_uuid"
    static let requestUUID = "request_uuid"
    static let enabledModules = "enabled_modules"
    static let enabledModulesVersions = "enabled_modules_versions"
    static let deepLinkURL = "deep_link_url"
    static let deepLinkQueryPrefix = "deep_link_param"
    static let deepLinkReferrerUrl = "deep_link_referrer_url"
    static let deepLinkReferrerApp = "deep_link_referrer_app"
    static let killVisitorSessionEvent = "event"
    static let traceId = "cp.trace_id"
    static let timedEventName = "timed_event_name"
    static let eventStart = "timed_event_start"
    static let eventStop = "timed_event_end"
    static let eventDuration = "timed_event_duration"
    static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
}

public enum TealiumKey {

    public static let updateConsentCookieEventNames = ["update_consent_cookie", "set_dns_state"]
    public static let jsNotificationName = "com.tealium.tagmanagement.jscommand"
    public static let jsCommand = "js"
    // used for remote commands
    public static let persistentData = "persistentData"
    public static let persistentVisitorId = "visitorId"
    public static let logLevelConfig = "com.tealium.logger.loglevel"
    public static let prod = "prod"
    public static let dev = "dev"
    public static let qa = "qa" // swiftlint:disable:this identifier_name
    public static let errorHeaderKey = "X-Error"
    public static let remoteAPIEventType = "remote_api"
    public static let tealiumURLScheme = "tealium"
    static let killVisitorSession = "kill_visitor_session"
    static let leaveTraceQueryParam = "leave_trace"
    static let traceIdQueryParam = "tealium_trace_id"
    static let deepLink = "deep_link"
}

public enum TealiumTrackType: String {
    case view           // Whenever content is displayed to the user.
    case event

    var description: String {
        switch self {
        case .view:
            return "view"
        case .event:
            return "event"
        }
    }
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
