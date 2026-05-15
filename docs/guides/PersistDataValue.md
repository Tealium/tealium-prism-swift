# PersistDataValue

The `PersistDataValue` transformation stores a value from the dispatch payload (or a constant) into the data layer with a configurable expiry and update policy. On the same dispatch, the effectively persisted value is also injected back into the payload so it is immediately available downstream. If the persistence fails or the update policy prevents the write, the dispatch is returned unchanged.

> **Requires:** `TealiumPrismExtensions`

## Registration

The `PersistDataValue` transformer is registered automatically when the `TealiumPrismExtensions` library is linked to your app (via the Objective-C `+load` mechanism). No additional setup is required. You only need to call `config.addModule()` explicitly if you want to enforce specific module-level settings:

```swift
// Explicit — use only when enforcing module-level settings
config.addModule(Modules.persistDataValueTransformer())
```

## Programmatic Configuration

Use `PersistDataValueSettingsBuilder` to configure the transformation:

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

## JSON Configuration

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
