# Collect

The Collect module is a `Dispatcher` module that sends tracking events to the Tealium Collect service. This module handles both single event dispatching and batch event processing, automatically optimizing delivery based on the number of events and visitor IDs. It supports customizable endpoints, profile overrides, and domain configuration for flexible deployment scenarios.

### Configuration Options

The Collect module provides the following configuration options:

| Setting | Key | Description | Default Value |
|---------|-----|-------------|---------------|
| URL | `url` | The URL used to send single events | `https://collect.tealiumiq.com/event` |
| Batch URL | `batch_url` | The URL used to send a batch of events | `https://collect.tealiumiq.com/bulk-event` |
| Override Profile | `override_profile` | Profile to override the `TealiumConfig.profile` in event data | None |
| Override Domain | `override_domain` | Domain to replace default URL domains (doesn't override explicit URLs) | None |

## Installation/Configuration

The Collect module can be configured using three different approaches:

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
        "Collect": {
            "module_type": "Collect"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "Collect": {
            "module_type": "Collect",
            "enabled": true,
            "order": 1,
            "configuration": {
                "url": "https://custom.collect.endpoint.com/event",
                "batch_url": "https://custom.collect.endpoint.com/bulk-event",
                "override_profile": "custom-profile",
                "override_domain": "custom.domain.com"
            },
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
                              Modules.collect(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.collect(forcingSettings: { builder in
                                  builder.setUrl("https://custom.collect.endpoint.com/event")
                                         .setBatchUrl("https://custom.collect.endpoint.com/bulk-event")
                                         .setOverrideProfile("custom-profile")
                                         .setOverrideDomain("custom.domain.com")
                                         .setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

### Multiple Collect Instances
The Collect module supports multiple instances with different configurations:

```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.collect(
                                  forcingSettings: { builder in
                                      builder.setModuleId("PrimaryCollect")
                                             .setUrl("https://primary.collect.endpoint.com/event")
                                  },
                                  { builder in
                                      builder.setModuleId("SecondaryCollect")
                                             .setUrl("https://secondary.collect.endpoint.com/event")
                                             .setRules(.and(["purchase_rule_id"]))
                                  }
                              ),
                              // other modules...
                          ])
```

The equivalent configuration in JSON format:

```json
{
    "modules": {
        "PrimaryCollect": {
            "module_type": "Collect",
            "module_id": "PrimaryCollect",
            "configuration": {
                "url": "https://primary.collect.endpoint.com/event"
            }
        },
        "SecondaryCollect": {
            "module_type": "Collect",
            "module_id": "SecondaryCollect",
            "configuration": {
                "url": "https://secondary.collect.endpoint.com/event"
            },
            "rules": {
                "operator": "and",
                "children": [
                    "purchase_rule_id"
                ]
            }
        }
    }
}
```

## Settings Builders Reference

The Collect module uses the `CollectSettingsBuilder` for configuration. This is an extension of the `DispatcherSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`
- `DispatcherSettingsBuilder.setMappings(_:)`

### Collect-specific methods:

- `CollectSettingsBuilder.setUrl(_:)`
- `CollectSettingsBuilder.setBatchUrl(_:)`
- `CollectSettingsBuilder.setOverrideProfile(_:)`
- `CollectSettingsBuilder.setOverrideDomain(_:)`
