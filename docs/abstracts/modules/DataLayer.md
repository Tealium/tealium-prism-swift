The DataLayer module is a `Collector` module that provides persistent data storage functionality for the Tealium SDK. This module acts as a centralized data repository where applications can store key-value pairs that will be automatically included in all tracking events. It supports data expiration, transactional operations, and real-time data updates, making it essential for maintaining consistent data across tracking calls.

> **Note:** This module cannot be disabled as it is a core component of the Tealium SDK.

### Collected Data Points

The DataLayer module collects all data that has been previously stored in it by the application. The specific data points depend on what has been added to the data layer:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Custom Data | *Variable* | Any data stored via `DataLayer.put(key:value:expiry:)` and similar methods | Application |

*Note: The actual keys and values depend on what data has been stored in the DataLayer by your application.*

## Installation/Configuration

The DataLayer module can be configured using three different approaches:

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
        "DataLayer": {
            "module_type": "DataLayer"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "DataLayer": {
            "module_type": "DataLayer",
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
                              Modules.dataLayer(),
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
                              Modules.dataLayer(forcingSettings: { builder in
                                  builder.setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

> **⚠️ Note:** This module cannot be disabled, and _should not_ have any rules applied to it, as it provides essential data storage functionality. The `setEnabled(false)` method will have no effect on this module.

## Settings Builders Reference

The DataLayer module uses the `DataLayerSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

Note: The `ModuleSettingsBuilder.setEnabled(_:)` method is available but has no effect since this module cannot be disabled.

# Usage
You can use the dataLayer by accessing an interface on the `Tealium` object.

```swift
tealium.dataLayer.put(key: "some_key", value: "some value", expiry: .forever).subscribe { result in
            // Optionally handle result here
        }
```

See more on the interface definition below.

# DataLayer
