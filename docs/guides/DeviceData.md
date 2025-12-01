# DeviceData

The DeviceData module is a `Collector` module that automatically enriches tracking data with comprehensive device information. This module gathers both static device characteristics (like CPU architecture and OS version) and dynamic information (like battery status and screen orientation) to provide detailed device context for all tracking events.

### Collected Data Points

The DeviceData module collects the following information:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| **Static Device Data** | | | |
| Architecture | `device_architecture` | CPU architecture (32 or 64-bit) | System info |
| CPU Type | `device_cputype` | Detailed CPU type (e.g., "ARM64e", "x86_64") | System info |
| Device | `device` | Consumer device name (e.g., "iPhone 13 Pro Max") | Device names API |
| Device Model | `device_model` | Consumer device name (e.g., "iPhone 13 Pro Max") | Device names API |
| Device Type | `device_type` | Apple model identifier (e.g., "iPhone14,3") | System info |
| Device Origin | `origin` | Device category ("mobile", "tv", "watch", "desktop") | Platform detection |
| Manufacturer | `device_manufacturer` | Device manufacturer ("Apple") | Static value |
| Model Variant | `model_variant` | Model variant identifier (e.g., "A2484") | Device names API |
| OS Build | `device_os_build` | OS build number | Bundle info |
| OS Name | `os_name` | Operating system name ("iOS", "tvOS", "watchOS", "macOS") | Platform detection |
| OS Version | `device_os_version` | Operating system version | System info |
| Platform | `platform` | Lowercase OS name | Platform detection |
| **Dynamic Device Data** | | | |
| Language | `device_language` | Primary device language | Locale info |
| Battery Percent | `device_battery_percent` | Battery charge percentage | UIDevice (iOS only) |
| Is Charging | `device_ischarging` | Whether device is charging | UIDevice (iOS only) |
| Orientation | `device_orientation` | Device orientation | UIDevice/System |
| Extended Orientation | `device_orientation_extended` | Detailed orientation info | UIDevice/System |
| Resolution | `device_resolution` | Physical screen resolution | Screen info |
| Logical Resolution | `device_logical_resolution` | Logical screen resolution | Screen info |
| **Memory Data (Optional)** | | | |
| App Memory Usage | `app_memory_usage` | Current app memory usage | System info |
| Memory Active | `memory_active` | Active memory | System info |
| Memory Free | `memory_free` | Free memory | System info |
| Memory Inactive | `memory_inactive` | Inactive memory | System info |
| Memory Compressed | `memory_compressed` | Compressed memory | System info |
| Memory Wired | `memory_wired` | Wired memory | System info |
| Physical Memory | `memory_physical` | Total physical memory | System info |

## Installation/Configuration

The DeviceData module can be configured using three different approaches:

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
        "DeviceData": {
            "module_type": "DeviceData"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "DeviceData": {
            "module_type": "DeviceData",
            "enabled": true,
            "order": 1,
            "configuration": {
                "device_names_url": "https://custom.endpoint.com/device_names.json",
                "memory_reporting_enabled": true,
                "battery_reporting_enabled": false,
                "screen_reporting_enabled": true
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
                              Modules.deviceData(),
                              // other modules...
                          ])
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.deviceData(forcingSettings: { builder in
                                  builder.setDeviceNamesUrl("https://custom.endpoint.com/device_names.json")
                                         .setMemoryReportingEnabled(true)
                                         .setBatteryReportingEnabled(false)
                                         .setScreenReportingEnabled(true)
                                         .setEnabled(true)
                                         .setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

## Settings Builders Reference

The DeviceData module uses the `DeviceDataSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

### DeviceData-specific methods:

- `DeviceDataSettingsBuilder.setDeviceNamesUrl(_:)` - Set custom URL for device names lookup
- `DeviceDataSettingsBuilder.setMemoryReportingEnabled(_:)` - Enable/disable memory usage reporting
- `DeviceDataSettingsBuilder.setBatteryReportingEnabled(_:)` - Enable/disable battery status reporting (default: true)
- `DeviceDataSettingsBuilder.setScreenReportingEnabled(_:)` - Enable/disable screen info reporting (default: true)
