The DeepLink module is a `Collector` module that automatically handles incoming deep links for attribution tracking and trace management. This module captures deep link URLs, extracts query parameters, manages referrer information, and integrates with the Trace module for debugging purposes. On iOS, the module automatically listens for deep link events unless explicitly disabled.

### Collected Data Points

The DeepLink module collects the following information when a deep link is handled:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Deep Link URL | `deep_link_url` | The complete URL of the deep link | Deep link event |
| Query Parameters | `deep_link_param_*` | Each query parameter prefixed with `deep_link_param_` | Deep link URL |
| Referrer URL | `deep_link_referrer_url` | The URL that referred to this deep link | Referrer parameter |
| Referrer App | `deep_link_referrer_app` | The app identifier that opened this deep link | Referrer parameter |

## Installation/Configuration

The DeepLink module can be configured using three different approaches:

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
        "DeepLink": {
            "module_type": "DeepLink"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "DeepLink": {
            "module_type": "DeepLink",
            "enabled": true,
            "order": 1,
            "rules": {
                "operator": "and",
                "children": [
                    "rule_id_from_settings"
                ]
            },
            "configuration": {
                "deep_link_trace_enabled": true,
                "send_deep_link_event": false
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
                              Modules.deepLink(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.deepLink(forcingSettings: { builder in
                                  builder.setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                                         .setDeepLinkTraceEnabled(true)
                                         .setSendDeepLinkEvent(false)
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Configuration Options

The DeepLink module supports the following configuration options:

| Setting | Key | Description | Default Value |
|---------|-----|-------------|---------------|
| Deep Link Trace Enabled | `deep_link_trace_enabled` | Enable or disable trace functionality from deep links. When enabled, QR codes from QR Trace tool will automatically join traces. | `true` |
| Send Deep Link Event | `send_deep_link_event` | Enable or disable sending deep link events. When enabled, a deep link event will be tracked automatically. | `false` |

## Settings Builders Reference

The DeepLink module uses the `DeepLinkSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

### DeepLink-specific methods:

- `DeepLinkSettingsBuilder.setDeepLinkTraceEnabled(_:)` - Enable or disable trace functionality from deep links
- `DeepLinkSettingsBuilder.setSendDeepLinkEvent(_:)` - Enable or disable automatic deep link event tracking

# Usage
Automatic deep link tracking is enabled by default in Tealium for iOS.

If you do not want deep links to be tracked automatically, you can disable automatic deep link tracking with the **_info.plist_** key **_TealiumAutotrackingDeepLinkEnabled_** set to `false`.

You can use the `DeepLinkHandler` manually by accessing an interface on the `Tealium` object.

```swift
tealium.deepLink.handle(link: url, referrer: .fromUrl(referrerUrl)).subscribe { result in
    // Optionally handle result here
}
```

See more on the interface definition below.

# DeepLinkHandler
