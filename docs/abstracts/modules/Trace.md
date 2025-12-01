The Trace module is a `Collector` module that provides debugging and testing functionality for the Tealium SDK. This module allows developers to join trace sessions for real-time event monitoring, leave traces when debugging is complete, and kill visitor sessions for testing purposes. When a trace is active, the trace ID is automatically added to all tracking events for server-side filtering and analysis.

### Collected Data Points

The Trace module collects the following information when a trace session is active:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Trace ID | `cp.trace_id` | The unique identifier for the active trace session (legacy compatibility) | Trace session |
| Trace ID | `tealium_trace_id` | The unique identifier for the active trace session | Trace session |

## Installation/Configuration

The Trace module can be configured using three different approaches:

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
        "Trace": {
            "module_type": "Trace"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "Trace": {
            "module_type": "Trace",
            "enabled": true,
            "order": 1,
            "rules": {
                "operator": "and",
                "children": [
                    "rule_id_from_settings"
                ]
            },
            "configuration": {
                "track_errors": true
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
                              Modules.trace(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.trace(forcingSettings: { builder in
                                  builder.setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                                         .setTrackErrors(true)
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Settings Builders Reference

The Trace module uses the `TraceSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

### Trace-specific Settings

- `TraceSettingsBuilder.setTrackErrors(_:)` - Enable or disable automatic error tracking during trace sessions (default: `false`)

# Usage
You can use the trace functionality by accessing an interface on the `Tealium` object.

```swift
// Join a trace session
tealium.trace.join(id: "trace_id").subscribe { result in
    // Optionally handle result here
}

// Leave the current trace session
tealium.trace.leave().subscribe { result in
    // Optionally handle result here
}

// Force end of visit for testing
tealium.trace.forceEndOfVisit().subscribe { result in
    // Handle the track result
}
```

> **⚠️ Note:** You can use trace directly from deep links, if the opened URL contains the right query parameter, and that's usually done with the QR trace tool on the platform. If you want to programmatically call trace, then, you can use the methods above.

See more on the interface definition below.

# Trace
