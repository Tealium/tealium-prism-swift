# TealiumData

The TealiumData module is a `Collector` module that automatically enriches tracking data with essential Tealium-specific information. This module provides core SDK metadata and configuration details for all tracking events. This module cannot be disabled as it provides fundamental data required by the Tealium platform.

> **Note:** This module cannot be disabled as it is a core component of the Tealium SDK.

### Collected Data Points

The TealiumData module collects the following information:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Account | `tealium_account` | Tealium account identifier | TealiumConfig |
| Profile | `tealium_profile` | Tealium profile identifier | TealiumConfig |
| Environment | `tealium_environment` | Tealium environment (dev, qa, prod) | TealiumConfig |
| Data Source | `tealium_datasource` | Data source identifier | TealiumConfig |
| Library Name | `tealium_library_name` | Name of the Tealium library | SDK constant |
| Library Version | `tealium_library_version` | Version of the Tealium library | SDK constant |
| Visitor ID | `tealium_visitor_id` | Unique visitor identifier | Visitor ID provider |
| Enabled Modules | `enabled_modules` | List of enabled module IDs | Modules manager |
| Enabled Modules Versions | `enabled_modules_versions` | List of enabled module versions | Modules manager |
| Random | `tealium_random` | Random 16-digit number for event deduplication | Generated per event |

## Installation/Configuration

The TealiumData module can be configured using three different approaches:

### Local and Remote Settings
Configure the module using local JSON settings file (via `settingsFile` parameter) and/or remote settings (via `settingsUrl` parameter):

```swift
var config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          settingsFile: "TealiumSettings",
                          settingsUrl: "https://tags.tiqcdn.com/dle/tealiummobile/lib/example_settings.json")
```

**Default initialization** - module will be initialized with default settings:
```json
{
    "modules": {
        "TealiumData": {
            "module_type": "TealiumData"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "TealiumData": {
            "module_type": "TealiumData",
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
                              Modules.tealiumData(),
                              // other modules...
                          ])
```

> **Note:** This module is automatically included and cannot be disabled, so it will be initialized even if not explicitly added to the modules list.

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.tealiumData(forcingSettings: { builder in
                                  builder.setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

> **⚠️ Note:** This module cannot be disabled, and _should not_ have any rules applied to it, as it provides essential Tealium platform data. The `setEnabled(false)` method will have no effect on this module.

## Settings Builders Reference

The TealiumData module uses the `TealiumDataSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

Note: The `ModuleSettingsBuilder.setEnabled(_:)` method is available but has no effect since this module cannot be disabled.
