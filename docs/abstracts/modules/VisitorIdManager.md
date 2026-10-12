The VisitorId module is a `Collector` module that owns the anonymous visitor ID: it creates and persists it, adds it to every tracking event, and can switch it automatically when an identity stored in the data layer changes (Visitor Switching). It is enabled by default. Other modules read the visitor ID synchronously through the `VisitorIdProvider` protocol, exposed via `ModuleManager`; apps read and observe it through `tealium.visitorId` (a `VisitorIdManager`) on the `Tealium` object.

### Collected Data Points

The VisitorId module collects the following information:

| Data Point | Key | Description | Source |
|------------|-----|-------------|--------|
| Visitor ID | `tealium_visitor_id` | The anonymous visitor identifier for this device | VisitorId module |

## Installation/Configuration

The VisitorId module can be configured using three different approaches:

### Local and Remote Settings
Configure the module using local JSON settings file (via `settingsFile` parameter) and/or remote settings (via `settingsUrl` parameter):

```swift
var config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          settingsFile: "TealiumSettings",
                          settingsUrl: "https://tags.tiqcdn.com/dle/tealiummobile/lib/example_settings.json")
```

**Default initialization** - the module is enabled by default, so no settings are needed to use it. Only if it's added with `Modules.visitorId(forcingSettings: nil)` is it initialized just when configured in settings, like this:
```json
{
    "modules": {
        "VisitorId": {
            "module_type": "VisitorId"
        }
    }
}
```

**Custom configuration** - module with specific settings:
```json
{
    "modules": {
        "VisitorId": {
            "module_type": "VisitorId",
            "enabled": true,
            "order": 1,
            "rules": {
                "operator": "and",
                "children": [
                    "rule_id_from_settings"
                ]
            },
            "configuration": {
                "visitor_identity_key": "email"
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
                              Modules.visitorId(),
                              // other modules...
                          ])
```

> **Note:** This module is automatically included, so it will be initialized with default settings even if not explicitly added to the modules list.

**Settings-driven initialization** - pass `nil` to initialize the module only when Local or Remote settings configure it:
```swift
modules: [
    Modules.visitorId(forcingSettings: nil),
    // other modules...
]
```

**Custom configuration** - module with enforced settings:
```swift
let config = TealiumConfig(account: "tealiummobile",
                          profile: "your-profile", 
                          environment: "dev",
                          modules: [
                              Modules.visitorId(forcingSettings: { builder in
                                  builder.setOrder(1)
                                         .setRules(.and(["rule_id_from_settings"]))
                                         .setVisitorIdentityKey("email")
                              }),
                              // other modules...
                          ])
```

> **⚠️ Important:** Programmatic settings are deep merged onto local and remote settings and will always take precedence. Only provide programmatic settings for configuration values that you never want to be changed remotely, as they will override any remote updates.

To disable the module, set `enabled: false` in its settings or call `setEnabled(false)` on its builder. See [Consequences of Disabling](#consequences-of-disabling) below.

## Configuration Options

The VisitorId module supports the following configuration options:

| Setting | Key | Description | Default Value |
|---------|-----|-------------|---------------|
| Visitor Identity Key | `visitor_identity_key` | The data layer key that holds the identity of the current user, used to drive Visitor Switching. | `nil` (Visitor Switching disabled) |

## Settings Builders Reference

The VisitorId module uses the `VisitorIdSettingsBuilder` for configuration. This is an extension of the `CollectorSettingsBuilder` which offers common settings like:

- `ModuleSettingsBuilder.setEnabled(_:)`
- `ModuleSettingsBuilder.setOrder(_:)`
- `RuleModuleSettingsBuilder.setRules(_:)`

### VisitorId-specific methods:

- `VisitorIdSettingsBuilder.setVisitorIdentityKey(_:)` - Set the data layer key that identifies the current user, enabling Visitor Switching

## Visitor Switching

Visitor Switching links visitor IDs to identities you place in the data layer, such as an email address or a user ID, so that the same person is recognized across logins on the same device.

Visitor Switching is disabled while no `visitor_identity_key` is configured. Once configured, the SDK has no notion of login or logout — it simply watches that data layer key:

- Writing a **new** identity to the key, when the visitor ID is not owned by another identity, links that identity to the current visitor ID.
- Writing a **known** identity (one seen before on this device) restores the visitor ID it was previously associated with.
- Writing a **different, unknown** identity generates a new visitor ID and links it to that identity.
- **Removing** the key from the data layer does not change the visitor ID; it marks the identity as absent.

## Resetting the Visitor ID

`regenerate()` always generates a new anonymous visitor ID. What happens to the identity association depends on whether an identity is present in the data layer (at the configured `visitor_identity_key`) at the time of the call:

- If an identity is present, it takes ownership of the new visitor ID, and its stored association is updated to point at it.
- If no identity is present, the new visitor ID is unowned: the next identity written to the data layer adopts it, and a returning identity restores its own previous visitor ID instead.

This gives two optional uses, neither of which is required:

- **Regenerate after logout** — remove the identity key from the data layer, then call `regenerate()`, so the departing identity keeps its old visitor ID and the device continues anonymously with a fresh one. Calling `regenerate()` while an identity is still present instead rebinds that identity to the new visitor ID.
- **Regenerate before login** — call `regenerate()` immediately before writing a new identity to the data layer, so that new identity can never adopt whatever visitor ID the device had before. Both calls go through the Tealium queue in call order, so the regenerate is guaranteed to land before the identity write that follows it.

`eraseLocalHistory()` erases every stored identity association, then generates a new anonymous visitor ID. If an identity is present at the time of the call, it is immediately re-associated with the new visitor ID, so one new association may exist afterwards; remove the identity from the data layer first to erase without leaving any association behind.

## Seeding the First Visitor ID

`TealiumConfig.existingVisitorId` seeds the very first visitor ID for this device — for example, to migrate an ID generated by a previous SDK. It only applies on first launch, before any visitor ID has been stored; it has no effect afterwards.

## Consequences of Disabling

While the VisitorId module is disabled:

- `tealium_visitor_id` is not added to tracking events.
- `tealium.visitorId` and its methods (`current()`, `regenerate()`, `eraseLocalHistory()`) resolve to a `.failure`.
- Identity-driven Visitor Switching stops: identity changes in the data layer are not observed.
- The Collect module still batches and sends events, grouping those without a visitor ID together.
- The ContextAPI module can't fetch engine responses: `fetchEngineResponse(engineID:)` fails with `ModuleError.moduleNotEnabled`.

# Usage
You can read and observe the visitor ID by accessing an interface on the `Tealium` object.

```swift
// Subscribe to the current visitor ID and every subsequent change
tealium.visitorId.subscribe { result in
    switch result {
    case .success(let visitorId):
        // Use the current visitor ID
        print("Visitor ID: \(visitorId)")
    case .failure(.tealiumError(let error)):
        // The Tealium instance failed to initialize or was shut down: this is the last emission
        print("Visitor ID no longer available: \(error)")
    case .failure(let error):
        // The VisitorId module is disabled: successes resume if it is re-enabled
        print("Failed to resolve visitor ID: \(error)")
    }
}.addTo(disposable)

// Or read it once
tealium.visitorId.current().subscribe { result in
    // Handle the result
}

// Generate a new anonymous visitor ID. If regenerating around a login or logout, see
// "Resetting the Visitor ID" above for where to place this call relative to the data-layer write.
tealium.visitorId.regenerate().subscribe { result in
    // Handle the result
}

// Erase every stored identity association on this device, then generate a new anonymous visitor ID
tealium.visitorId.eraseLocalHistory().subscribe { result in
    // Handle the result
}
```

While the module is disabled, every method completes with a `.failure`, and subscribers to visitorId changes receive a `.failure` that is followed by successes again if the module is later re-enabled. If the `Tealium` instance failed to initialize, or is shut down, every method completes with a `.failure`, and subscribers to visitorId changes receive a single `.failure` after which the subscription completes.

If `regenerate()` or `eraseLocalHistory()` can't store their changes, they complete with a `.failure`, but the new visitor ID is still used until the app is relaunched. In this case nothing is stored, so on the next launch the previous visitor ID and every stored association are restored.

See more on the interface definition below.

# VisitorIdManager
