# TimeData

The TimeData module is a `Collector` module that automatically enriches tracking data with comprehensive timestamp information. This module takes the initial timestamp from the dispatch context and generates multiple time-related data points in various formats, including UTC, local time, timezone information, and Unix timestamps.

### Collected Data Points

The TimeData module collects the following information:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Timestamp UTC | `tealium_timestamp_utc` | The timestamp in ISO 8601 UTC string format | Derived from initial timestamp |
| Timestamp Local | `tealium_timestamp_local` | The timestamp in ISO 8601 Local string format | Derived from initial timestamp |
| Timestamp Local with Offset | `tealium_timestamp_local_with_offset` | The timestamp in ISO 8601 Local string with offset (+/-HH:mm or Z) | Derived from initial timestamp |
| Timezone Offset | `tealium_timestamp_offset` | The timezone offset in decimal hours (e.g., +8, -4.5) | Current timezone |
| Timestamp Unix | `tealium_timestamp_epoch` | The timestamp in Unix seconds | Derived from initial timestamp |
| Timestamp Unix Milliseconds | `tealium_timestamp_epoch_milliseconds` | The timestamp in Unix milliseconds | From dispatch context |
| Timestamp Timezone | `tealium_timestamp_timezone` | The time zone identifier (e.g., "America/New_York") | Current timezone |

## Installation/Configuration

The TimeData module can be configured using three different approaches:

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
        "TimeData": {
            "module_type": "TimeData"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "TimeData": {
            "module_type": "TimeData",
            "enabled": true,
            "order": 1,
            "rules": {
                "operator": "and",
                "children": [
                    "rule_id_from_settings"
                ]
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
                              Modules.timeData(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.timeData(forcingSettings: { builder in
                                  builder.setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Settings Builders Reference

The TimeData module uses the `TimeDataSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`
