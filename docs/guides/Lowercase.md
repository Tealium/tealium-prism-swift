# Lowercase

The `Lowercase` transformation converts string values in the dispatch payload to lowercase. It requires explicit configuration: either lowercase all strings in the payload, or target specific keys. Strings nested inside arrays and dictionaries are also lowercased recursively. Non-string values (numbers, booleans, etc.) are left unchanged. The values at `tealium_visitor_id`, `cp.trace_id`, and `tealium_trace_id` are always left unchanged when using `lowercaseAllVariables()`, unless those keys are explicitly listed in `lowercaseVariables(_:)`. A transformation with no `variables` configuration is treated as a no-op — the dispatch passes through unchanged.

> **Requires:** `TealiumPrismExtensions`

## Registration

The `Lowercase` transformer is registered automatically when the `TealiumPrismExtensions` library is linked to your app (via the Objective-C `+load` mechanism). No additional setup is required. You only need to call `config.addModule()` explicitly if you want to enforce specific module-level settings:

```swift
// Explicit — use only when enforcing module-level settings
config.addModule(Modules.lowercaseTransformer())
```

## Programmatic Configuration

Use `LowercaseSettingsBuilder` to configure the transformation:

```swift
// Lowercase all strings
let lowerAll = LowercaseSettingsBuilder(id: "lowercase-all")
    .lowercaseAllVariables()
    .setScope(.afterCollectors)

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

## JSON Configuration

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
