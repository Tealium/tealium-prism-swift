The Extensions module provides a set of built-in transformers that cover the most common data manipulation needs in the Tealium SDK. Instead of writing a custom `Transformer` from scratch, you can configure these ready-made transformers through a fluent builder API or via JSON settings.

## Overview

The Extensions module includes three transformers:

- **`SetDataValues`** — Copies values between keys or sets constant values in the dispatch payload.
- **`PersistDataValue`** — Writes a value from the payload (or a constant) to the data layer with a configurable expiry and update policy, then injects the persisted value back into the current dispatch.
- **`Lowercase`** — Lowercases all string values in the dispatch payload, or targets specific keys.

Each transformer is configured through its dedicated settings builder, which you attach to your `TealiumConfig` via `config.setTransformation(_:)` like any other transformation. See the [Transformations](Transformations.html) documentation for a full explanation of scope, conditions, and how transformations fit into the dispatch pipeline.

## Registration

The Extensions module registers its transformers automatically when linked to your app (via the Objective-C `+load` mechanism). No additional setup is required if you are using SPM or CocoaPods. You only need to call `config.addModule()` explicitly if you want to enforce specific module-level settings:

```swift
// Automatic (default) — transformers are registered without any code
// Nothing to do.

// Explicit — use this only when you need to enforce module-level settings
config.addModule(Modules.setDataValuesTransformer())
config.addModule(Modules.persistDataValueTransformer())
config.addModule(Modules.lowercaseTransformer())
```

Transformations themselves (the actual rules for each transformer) are configured separately and added to the SDK configuration with `config.setTransformation(_:)`.

## Scopes

All transformations share a `setScope(_:)` method inherited from `TransformationSettingsBuilder`. Three scopes are available:

| Scope | When it runs |
|---|---|
| `.afterCollectors` | After all collectors have run, before the consent check and dispatch queues |
| `.allDispatchers` | Just before a dispatch is sent to every registered dispatcher |
| `.dispatchers(["id1", "id2", ...])` | Just before a dispatch is sent to the listed dispatchers only |

```swift
// Run only before the Collect dispatcher sends its batch
let transformation = SetDataValuesSettingsBuilder(id: "pre-collect")
    .setConstant("batch", destination: .key("send_mode"))
    .setScope(.dispatchers([Modules.Types.collect]))
    .setOrder(1)

config.setTransformation(transformation)
```

```swift
// Run before every dispatcher
let transformation = LowercaseSettingsBuilder(id: "lowercase-all-dispatchers")
    .setScope(.allDispatchers)
    .setOrder(1)

config.setTransformation(transformation)
```

**JSON representation:**

| Scope | JSON value |
|---|---|
| `.afterCollectors` | `"scope": "aftercollectors"` |
| `.allDispatchers` | `"scope": "alldispatchers"` |
| `.dispatchers([...])` | `"scope": ["Collect", "Trace"]` (array of dispatcher IDs) |

## SetDataValues

The `SetDataValues` transformer copies values between locations in the dispatch payload or injects constant values. It applies all configured operations in sequence on every dispatch that matches the transformation's conditions and scope.

### Programmatic Configuration

Use `SetDataValuesSettingsBuilder` to define one or more operations:

```swift
// Copy a value from one key to another
let copyOperation = SetDataValuesSettingsBuilder(id: "copy-user-id")
    .setFrom(.key("user_id"), to: .key("visitor_id"))
    .setScope(.afterCollectors)
    .setOrder(1)

config.setTransformation(copyOperation)
```

```swift
// Set a constant value at a given key
let setConstant = SetDataValuesSettingsBuilder(id: "set-platform")
    .setConstant("ios", to: .key("platform"))
    .setScope(.afterCollectors)
    .setOrder(1)

config.setTransformation(setConstant)
```

```swift
// Mix reference and constant operations in one transformation
let combined = SetDataValuesSettingsBuilder(id: "enrich-payload")
    .setFrom(.key("raw_email"), to: .key("email"))
    .setConstant("mobile", to: .key("channel"))
    .setScope(.afterCollectors)
    .setOrder(1)

config.setTransformation(combined)
```

**Using nested paths** — use `.path(_:)` with `JSONObjectPath` to target nested keys:

```swift
let nested = SetDataValuesSettingsBuilder(id: "map-nested")
    .setFrom(
        .path(JSONPath["user"]["profile"]["name"]),
        to: .key("user_name")
    )
    .setScope(.afterCollectors)
    .setOrder(1)
config.setTransformation(nested)
```

**Builder methods:**

| Method | Description |
|---|---|
| `setFrom(_ input: ReferenceContainer, to destination: ReferenceContainer)` | Copies the value at `input` to `destination` |
| `setConstant(_ constant: DataInput, to destination: ReferenceContainer)` | Sets a constant value at `destination` |

If the source key is not present in the payload, the operation is silently skipped. A transformation with no operations configured is a no-op — the dispatch passes through unchanged.

### JSON Configuration

```json
{
  "transformation_id": "enrich-payload",
  "transformer_id": "SetDataValues",
  "scope": "aftercollectors",
  "order": 1,
  "configuration": {
    "operations": [
      {
        "input": { "key": "raw_email" },
        "destination": { "key": "email" }
      },
      {
        "input": { "value": "mobile" },
        "destination": { "key": "channel" }
      },
      {
        "input": { "path": "user.profile.name" },
        "destination": { "key": "user_name" }
      }
    ]
  }
}
```

**Input formats:**

| Intent | JSON shape |
|---|---|
| Reference (root key) | `{"key": "some_key"}` |
| Reference (nested path) | `{"path": "parent.child.grandchild"}` |
| Constant value | `{"value": <any JSON value>}` |

**Destination format** follows the same reference shapes (`key` or `path`).

## PersistDataValue

The `PersistDataValue` transformer stores a value from the dispatch payload (or a constant) into the data layer. On the same dispatch, the effective persisted value is also injected back into the payload so it is immediately available downstream. If the persistence fails or the update policy prevents the write, the dispatch is returned unchanged.

### Programmatic Configuration

```swift
// Persist a payload value to the data layer (session-scoped by default)
let persistUserId = PersistDataValueSettingsBuilder(id: "persist-user-id")
    .persistFrom(.key("user_id"), to: .key("persisted_user_id"))
    .setScope(.dispatchers(["Analytics", "Collect"]))
    .setOrder(1)

config.setTransformation(persistUserId)
```

```swift
// Persist a constant value, never expire it, and never overwrite once set
let persistAppVersion = PersistDataValueSettingsBuilder(id: "persist-app-version")
    .persistConstant("2.4.0", to: .key("first_seen_version"))
    .setExpiryPolicy(.forever)
    .setUpdatePolicy(.keepFirstValue)
    .setScope(.afterCollectors)
    .setOrder(1)

config.setTransformation(persistAppVersion)
```

```swift
// Persist for a custom duration
let persistCampaign = PersistDataValueSettingsBuilder(id: "persist-campaign")
    .persistFrom(.key("utm_campaign"), to: .key("last_campaign"))
    .setExpiryPolicy(.duration(30.days))
    .setScope(.afterCollectors)
    .setOrder(1)

config.setTransformation(persistCampaign)
```

**Builder methods:**

| Method | Description |
|---|---|
| `persistConstant(_:to:)` | Persist a constant value |
| `persistFrom(_:to:)` | Persist the value found at `input` in the dispatch payload |
| `setExpiryPolicy(_:)` | How long the data layer value lives. Default: `.session` |
| `setUpdatePolicy(_:)` | Whether subsequent writes can overwrite the stored value. Default: `.allowUpdate` |

**`ExpiryPolicy` options:**

| Value | Description |
|---|---|
| `.session` | Cleared when the session ends (default) |
| `.untilRestart` | Cleared on the next app launch |
| `.forever` | Never expires |
| `.duration(TimeFrame)` | Expires after the given time frame |

**`UpdatePolicy` options:**

| Value | Description |
|---|---|
| `.allowUpdate` | Subsequent persists overwrite the stored value (default) |
| `.keepFirstValue` | The first successfully written value is preserved; later writes are ignored |

### JSON Configuration

```json
{
  "transformation_id": "persist-user-id",
  "transformer_id": "PersistDataValue",
  "scope": ["Analytics", "Collect"],
  "order": 1,
  "configuration": {
    "input": { "key": "user_id" },
    "destination": { "key": "persisted_user_id" },
    "duration": -2,
    "update_policy": "allowUpdate"
  }
}
```

**`duration` encoding:**

| Value | Meaning |
|---|---|
| `-1` | `.forever` |
| `-2` | `.session` |
| `-3` | `.untilRestart` |
| `>= 0` | Seconds until expiry (`.duration`) |

**`update_policy` values:** `"allowUpdate"` or `"keepFirstValue"` (case-insensitive).

**Constant input:**

```json
{
  "configuration": {
    "input": { "value": "2.4.0" },
    "destination": { "key": "first_seen_version" },
    "duration": -1,
    "update_policy": "keepFirstValue"
  }
}
```

## Lowercase

The `Lowercase` transformer converts string values in the dispatch payload to lowercase. By default it lowercases every string in the payload, including strings nested inside arrays and dictionaries. Non-string values (numbers, booleans, etc.) are left unchanged. The values at `tealium_visitor_id`, `cp.trace_id`, and `tealium_trace_id` are always left unchanged, unless those keys are explicitly listed in the targeted variables.

### Programmatic Configuration

```swift
// Lowercase all strings
let lowerAll = LowercaseSettingsBuilder(id: "lowercase-all")
    .lowercaseAllVariables()

config.setTransformation(lowerAll)
```

```swift
// Lowercase only specific keys
let lowerSelected = LowercaseSettingsBuilder(id: "lowercase-email-name")
    .lowercaseVariables([.key("email"), .key("user_name")])
    .setScope(.allDispatchers)
    .setOrder(1)

config.setTransformation(lowerSelected)
```

**Builder methods:**

| Method | Description |
|---|---|
| `lowercaseAllVariables()` | Lowercase all string values in the payload |
| `lowercaseVariables(_ variables: [ReferenceContainer])` | Lowercase only the specified keys |

**Recursive behaviour:** Both modes descend into array elements and nested dictionaries recursively. Non-string scalar values (numbers, booleans) are left unchanged in both modes.

### JSON Configuration

```json
{
  "transformation_id": "lowercase-all",
  "transformer_id": "Lowercase",
  "scope": "aftercollectors",
  "order": 1,
  "configuration": {
    "variables": "allvariables"
  }
}
```

```json
{
  "transformation_id": "lowercase-email-name",
  "transformer_id": "Lowercase",
  "scope": "alldispatchers",
  "order": 1,
  "configuration": {
    "variables": [
      { "key": "email" },
      { "key": "user_name" }
    ]
  }
}
```

**Configuration keys:**

| Key | Type | Description |
|---|---|---|
| `variables` | `"allvariables"` or `Array<ReferenceContainer>` | `"allvariables"` (case-insensitive) to lowercase all strings; an array of references to target specific keys |

> **Note:** A missing `variables` key is invalid — the transformation is treated as a no-op and the dispatch passes through unchanged. An empty array is valid and also results in a no-op.

## Combining Multiple Transformers

The built-in transformers compose naturally. A common pattern is to persist an incoming value, normalize it, and copy it to a standardized key, all within the `afterCollectors` scope:

```swift
// 1. Persist the raw campaign tag for 30 days
let persistCampaign = PersistDataValueSettingsBuilder(id: "persist-campaign")
    .persistFrom(.key("utm_campaign"), to: .key("last_campaign"))
    .setExpiryPolicy(.duration(30.days))
    .setUpdatePolicy(.allowUpdate)
    .setScope(.afterCollectors)
    .setOrder(1)

// 2. Copy the persisted value to a canonical key expected by the backend
let copyToCanonical = SetDataValuesSettingsBuilder(id: "map-campaign")
    .setFrom(.key("last_campaign"), to: .key("campaign_name"))
    .setScope(.afterCollectors)
    .setOrder(2)

// 3. Lowercase the canonical key to ensure consistent casing
let normalizeCase = LowercaseSettingsBuilder(id: "lowercase-campaign")
    .lowercaseVariables([.key("campaign_name")])
    .setScope(.afterCollectors)
    .setOrder(3)

config.setTransformation(persistCampaign)
config.setTransformation(copyToCanonical)
config.setTransformation(normalizeCase)
```

Use `setOrder(_:)` to explicitly control execution sequence within a scope — lower values run first. Transformations without an explicit order run last.

## Conclusion

The built-in transformers in the Extensions module handle the most common data manipulation tasks — copying, persisting, and normalizing payload values — without requiring custom `Transformer` implementations. Use the dedicated settings builders for programmatic configuration or supply the equivalent JSON via remote or local settings files.
