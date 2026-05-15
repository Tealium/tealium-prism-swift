# SetDataValues

The `SetDataValues` transformation copies values between keys or sets constant values in the dispatch payload. It applies all configured operations in sequence on every dispatch that matches the transformation's conditions and scope.

> **Requires:** `TealiumPrismExtensions`

## Registration

The `SetDataValues` transformer is registered automatically when the `TealiumPrismExtensions` library is linked to your app (via the Objective-C `+load` mechanism). No additional setup is required. You only need to call `config.addModule()` explicitly if you want to enforce specific module-level settings:

```swift
// Explicit — use only when enforcing module-level settings
config.addModule(Modules.setDataValuesTransformer())
```

## Programmatic Configuration

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

## JSON Configuration

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
