The Lifecycle module is a `Collector` module that automatically tracks application lifecycle events — launch, wake, and sleep. It maintains persistent counters and timestamps across sessions, detects crashes, tracks app version updates, and provides rich lifecycle metrics to the lifecycle events (or, optionally, to all tracked events). By default, the module automatically listens for application status changes and tracks corresponding lifecycle events without requiring manual intervention.

### Collected Data Points

The Lifecycle module collects the following information when lifecycle events occur:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Lifecycle Type | `lifecycle_type` | The type of lifecycle event: `launch`, `wake`, or `sleep` | Lifecycle event (only on lifecycle events) |
| Day of Week (Local) | `lifecycle_dayofweek_local` | Day of the week (1-7) at the time of the event, in the device's local timezone | Event timestamp |
| Hour of Day (Local) | `lifecycle_hourofday_local` | Hour of the day (0-23) at the time of the event, in the device's local timezone | Event timestamp |
| Days Since First Launch | `lifecycle_dayssincelaunch` | Number of complete days since the first launch after install | Event timestamp vs. first launch timestamp |
| Days Since Last Wake | `lifecycle_dayssincelastwake` | Number of complete days since the last launch or wake event | Event timestamp vs. last wake timestamp |
| Days Since Update | `lifecycle_dayssinceupdate` | Number of complete days since the app was updated (only present if an update has occurred) | Event timestamp vs. update timestamp |
| First Launch Date | `lifecycle_firstlaunchdate` | ISO 8601 formatted date of the first launch after install | Persisted storage |
| First Launch Date (MM/DD/YYYY) | `lifecycle_firstlaunchdate_MMDDYYYY` | First launch date in MM/DD/YYYY format | Persisted storage |
| Last Launch Date | `lifecycle_lastlaunchdate` | ISO 8601 formatted date of the last launch event that occurred *before* the current event | Persisted storage |
| Last Wake Date | `lifecycle_lastwakedate` | ISO 8601 formatted date of the last launch or wake event that occurred *before* the current event | Persisted storage |
| Last Sleep Date | `lifecycle_lastsleepdate` | ISO 8601 formatted date of the last sleep event that occurred *before* the current event | Persisted storage |
| Is First Launch | `lifecycle_isfirstlaunch` | `true` only on the very first launch after install | Lifecycle event (launch only) |
| Is First Launch After Update | `lifecycle_isfirstlaunchupdate` | `true` only on the first launch after an app version change | Lifecycle event (launch only) |
| Is First Wake Today | `lifecycle_isfirstwaketoday` | `true` on the first launch or wake event of the calendar day | Lifecycle event (launch/wake only) |
| Is First Wake This Month | `lifecycle_isfirstwakemonth` | `true` on the first launch or wake event of the calendar month | Lifecycle event (launch/wake only) |
| Did Detect Crash | `lifecycle_diddetectcrash` | `true` when a launch follows another launch or wake without an intervening sleep (indicates a likely crash) | Lifecycle event (launch only) |
| Launch Count | `lifecycle_launchcount` | Number of launch events since install or the last app update | Persisted storage |
| Wake Count | `lifecycle_wakecount` | Number of wake and launch events since install or the last app update | Persisted storage |
| Sleep Count | `lifecycle_sleepcount` | Number of sleep events since install or the last app update | Persisted storage |
| Total Launch Count | `lifecycle_totallaunchcount` | Total number of launch events since install (not reset on update) | Persisted storage |
| Total Wake Count | `lifecycle_totalwakecount` | Total number of wake and launch events since install (not reset on update) | Persisted storage |
| Total Sleep Count | `lifecycle_totalsleepcount` | Total number of sleep events since install (not reset on update) | Persisted storage |
| Total Crash Count | `lifecycle_totalcrashcount` | Total number of detected crashes since install (not reset on update) | Persisted storage |
| Seconds Awake | `lifecycle_secondsawake` | Aggregate seconds the app was in the foreground during the current session (not present on launch events). On `wake` events, reflects only foreground time accumulated in earlier foreground periods within this app session. On `sleep` events, includes the foreground period that just ended. | Computed from wake/sleep timestamps |
| Prior Seconds Awake | `lifecycle_priorsecondsawake` | Aggregate seconds the app was in the foreground during the previous session. Only present on launch events, including the first launch after install (where it will be `0`). | Persisted storage |
| Total Seconds Awake | `lifecycle_totalsecondsawake` | Total seconds the app has been in the foreground since install. Updated on sleep events, but always included. | Persisted storage |
| Update Launch Date | `lifecycle_updatelaunchdate` | ISO 8601 formatted date of the first launch after the most recent app version update (only present if an update has occurred) | Persisted storage |
| Autotracked | `autotracked` | `true` when the event was triggered by automatic tracking. Only present when auto-tracking is enabled and the lifecycle event was generated automatically. | Lifecycle module |

## Installation/Configuration

The Lifecycle module can be configured using three different approaches:

### Local and Remote Settings
Configure the module using local JSON settings file (via `settingsFile` parameter) and/or remote settings (via `settingsUrl` parameter):

```swift
var config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile",
                          environment: "dev",
                          settingsFile: "TealiumSettings",
                          settingsUrl: "https://tags.tiqcdn.com/dle/tealiummobile/lib/example_settings.json")
```

**Default initialization** - module will be initialized only if configured in settings file specified:
```json
{
    "modules": {
        "Lifecycle": {
            "module_type": "Lifecycle"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "Lifecycle": {
            "module_type": "Lifecycle",
            "enabled": true,
            "order": 1,
            "rules": {
                "operator": "and",
                "children": [
                    "rule_id_from_settings"
                ]
            },
            "configuration": {
                "autotracking_enabled": true,
                "session_timeout": 1440,
                "tracked_lifecycle_events": ["launch", "wake", "sleep"],
                "data_target": "lifecycleEventsOnly"
            }
        }
    }
}
```

When both local and remote settings are provided, they are deep merged with remote settings taking priority.

### Programmatic Configuration
Configure the module programmatically by adding it to the `modules` parameter in `TealiumConfig`.

**Default initialization** - module will be initialized with default settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile",
                          environment: "dev",
                          modules: [
                              Modules.lifecycle(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile",
                          environment: "dev",
                          modules: [
                              Modules.lifecycle(forcingSettings: { builder in
                                  builder.setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                                         .setAutoTrackingEnabled(true)
                                         .setSessionTimeoutInMinutes(1440)
                                         .setTrackedLifecycleEvents([.launch, .wake, .sleep])
                                         .setDataTarget(.lifecycleEventsOnly)
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Configuration Options

The Lifecycle module supports the following configuration options:

| Setting | Key | Description | Default Value |
|---------|-----|-------------|---------------|
| Auto-Tracking Enabled | `autotracking_enabled` | When `true`, lifecycle events are tracked automatically based on application status changes. When `false`, lifecycle calls must be made manually via the `Lifecycle` interface, or lifecycle metrics will be incorrect. Manual tracking calls return a `manualTrackNotAllowed` error when auto-tracking is enabled. | `true` |
| Session Timeout (Minutes) | `session_timeout` | If this timeout has been exceeded while the app is backgrounded, the next foreground event will be treated as a `launch` rather than a `wake`. Pass `-1` for infinite session duration (foreground after any background duration will always be a `wake`). | `1440` (24 hours) |
| Tracked Lifecycle Events | `tracked_lifecycle_events` | Lifecycle events to be tracked (sent as dispatches). Events not in this list are still *registered* internally (counters and timestamps update), but no dispatch is sent. | `["launch", "wake", "sleep"]` (all events) |
| Data Target | `data_target` | Controls which dispatches include lifecycle data as a collector. When `lifecycleEventsOnly`, lifecycle data is only attached to lifecycle event dispatches. When `allEvents`, lifecycle data is attached to all dispatches (except those originating from the Lifecycle module itself). | `lifecycleEventsOnly` |

## Settings Builders Reference

The Lifecycle module uses the `LifecycleSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

### Lifecycle-specific methods:

- `LifecycleSettingsBuilder.setAutoTrackingEnabled(_:)` - Enable or disable automatic lifecycle tracking
- `LifecycleSettingsBuilder.setSessionTimeoutInMinutes(_:)` - Set the session timeout duration in minutes
- `LifecycleSettingsBuilder.setTrackedLifecycleEvents(_:)` - Set which lifecycle events generate dispatches
- `LifecycleSettingsBuilder.setDataTarget(_:)` - Set whether lifecycle data is attached to all events or only lifecycle events

## Event Order Validation

The module enforces a strict event order to maintain data integrity:

- **Launch**: Valid as the first event in the current process lifetime (i.e., before any launch has been registered since the app started). A second launch event in the same process lifetime is invalid and will throw an `invalidEventOrder` error. Crash detection occurs on a fresh app start when the persisted last event indicates the app never went to sleep before terminating.
- **Sleep**: Valid only after a `launch` or `wake` event.
- **Wake**: Valid only after a `sleep` event.

Invalid event order in manual tracking mode throws a `LifecycleError.invalidEventOrder` error. In auto-tracking mode, invalid sequences are logged and ignored.

## Crash Detection

Crashes are detected heuristically: if the last recorded lifecycle event was a `launch` or `wake` (meaning the app never went to sleep/background properly), and a new `launch` occurs, the module concludes the app likely crashed. On such launches:

- `lifecycle_diddetectcrash` is set to `true`
- `lifecycle_totalcrashcount` is incremented

Crash detection runs only when a launch event is accepted and recorded; invalid event orders that are ignored do not increment crash counters.

## App Version Update Detection

On each launch, the module compares the current app version (`CFBundleShortVersionString` or `CFBundleVersion`) against the cached version. If a change is detected:

- `lifecycle_isfirstlaunchupdate` is set to `true` on that launch event
- `lifecycle_updatelaunchdate` is set to the current timestamp
- Session counters (`lifecycle_launchcount`, `lifecycle_wakecount`, `lifecycle_sleepcount`) are reset, then the launch itself is registered — so the first post-update launch dispatch will report `lifecycle_launchcount=1`, `lifecycle_wakecount=1`, `lifecycle_sleepcount=0`
- Total counters are not affected

# Usage
You can use the lifecycle functionality by accessing an interface on the `Tealium` object.

```swift
// Manual tracking (only when auto-tracking is disabled)
tealium.lifecycle().launch().subscribe { result in
    // Optionally handle result here
}

tealium.lifecycle().sleep().subscribe { result in
    // Optionally handle result here
}

tealium.lifecycle().wake().subscribe { result in
    // Optionally handle result here
}

// With optional custom data
tealium.lifecycle().launch(["custom_key": "custom_value"]).subscribe { result in
    // Optionally handle result here
}
```

> **⚠️ Note:** Manual tracking methods (`launch()`, `wake()`, `sleep()`) will return a `manualTrackNotAllowed` error if auto-tracking is enabled. Disable auto-tracking first if you need manual control.

See more on the interface definition below.

# Lifecycle
