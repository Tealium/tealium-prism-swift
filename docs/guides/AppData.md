# AppData

The AppData module is a `Collector` module that automatically enriches tracking data with essential application metadata. This module automatically gathers application-specific information from the main app Bundle and makes it available to all tracking events.

### Collected Data Points

The AppData module collects the following information:

| Data Point | Key | Description | Bundle Key |
|------------|-----|-------------|------------|
| App UUID | `app_uuid` | Random identifier persistent through app installation lifetime (e.g., "4AB81234-C2A8-46DE-9AED-7ACE555521E0") | Generated |
| App Build | `app_build` | Build number (e.g., "42") | `CFBundleVersion` |
| App Name | `app_name` | Application display name | `CFBundleName` |
| App rDNS | `app_rdns` | Reverse DNS identifier (e.g., "com.example.myapp") | `CFBundleIdentifier` |
| App Version | `app_version` | User-facing version (e.g., "1.0.0") | `CFBundleShortVersionString` |

## Installation/Configuration

The AppData module can be configured using three different approaches:

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
        "AppData": {
            "module_type": "AppData"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "AppData": {
            "module_type": "AppData",
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
                              Modules.appData(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.appData(forcingSettings: { builder in
                                  builder.setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Settings Builders Reference

The AppData module uses the `AppDataSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

