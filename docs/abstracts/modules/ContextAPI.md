The ContextAPI module provides integration with the Tealium Context API service, allowing applications to retrieve real-time visitor profile data from AudienceStream for personalization and insights. This module is neither a `Collector` nor a `Dispatcher` module - it provides a specialized API interface for fetching visitor data including audiences, badges, and attributes from configured Context API engines. The module enables high-performance, customizable data retrieval for real-time visitor personalization use cases.

## Installation/Configuration

The ContextAPI module can be configured using three different approaches:

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
        "ContextAPI": {
            "module_type": "ContextAPI",
            "configuration": {
                "context_api_region": "us-east-1"
            }
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "ContextAPI": {
            "module_type": "ContextAPI",
            "enabled": true,
            "order": 1,
            "rules": {
                "operator": "and",
                "children": [
                    "rule_id_from_settings"
                ]
            },
            "configuration": {
                "context_api_region": "us-east-1",
                "context_api_referrer": "https://example.com"
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
                              Modules.contextAPI(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.contextAPI(forcingSettings: { builder in
                                  builder.setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                                         .setRegion(.usEast)
                                         .setReferrer("https://example.com")
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Configuration Options

The ContextAPI module supports the following configuration options:

| Setting | Key | Description | Default Value |
|---------|-----|-------------|---------------|
| Region | `context_api_region` | The AWS region where the Context API engine is hosted. Determines which Tealium AudienceStream instance the API calls are made against. | *Required* |
| Referrer | `context_api_referrer` | The referrer URL for Context API requests. If not provided, it will be generated automatically. | `nil` |

## Settings Builders Reference

The ContextAPI module uses the `ContextAPISettingsBuilder` for configuration. This is an extension of the `ModuleSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`

### ContextAPI-specific methods:

- `ContextAPISettingsBuilder.setRegion(_:)` - Set the AWS region for the Context API (required)
- `ContextAPISettingsBuilder.setReferrer(_:)` - Set the referrer URL for API requests

# Usage
You can use the ContextAPI by accessing an interface on the `Tealium` object.

```swift
tealium.contextAPI().fetchEngineResponse(engineID: "your-engine-id").subscribe { result in
    switch result {
    case .success(let response):
        // Handle the engine response data
        print("Audiences: \(response.audiences ?? [])")
        print("Badges: \(response.badges ?? [])")
        print("Properties: \(response.properties ?? [:])")
    case .failure(let error):
        // Handle the error
        print("Failed to fetch engine response: \(error)")
    }
}
```

The `fetchEngineResponse` method can fail with a `ModuleError`, eventually encapsulating a `ContextAPIError`. 

Fetching requires the visitor ID, so it also fails with `ModuleError.moduleNotEnabled` while the VisitorId module is disabled. A request still in progress when the ContextAPI module shuts down fails with `ModuleError.moduleShutdown`.

See more on the interface definition below.

# ContextAPI
