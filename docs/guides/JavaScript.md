# JavaScript

The `JavaScript` transformation executes user-provided JavaScript code against each dispatch payload using Apple's JavaScriptCore engine. It is the most flexible built-in transformation — the script can read and modify any key in the payload, call back into the SDK to fire additional tracking calls, read and write to the persistent data layer, or drop the dispatch entirely.

> **Requires:** `TealiumPrismJavaScriptTransformer`
>
> **Platform note:** Not available on watchOS.

## Registration

The JavaScript transformer is registered automatically when the `TealiumPrismJavaScriptTransformer` library is linked to your app (via the Objective-C `+load` mechanism). No additional setup is required. You only need to call `config.addModule()` explicitly if you want to enforce specific module-level settings:

```swift
// Explicit — use only when enforcing module-level settings
config.addModule(Modules.javaScriptTransformer())
```

## Programmatic Configuration

Use `JavaScriptTransformationSettingsBuilder` to provide the JavaScript code to execute:

```swift
// Add a constant value to every dispatch
let addPlatform = JavaScriptTransformationSettingsBuilder(id: "add-platform")
    .setJsCode("payload.platform = 'ios'")
    .setScope(.afterCollectors)
    .setOrder(1)

config.setTransformation(addPlatform)
```

```swift
// Conditionally drop test events in production
let dropTestEvents = JavaScriptTransformationSettingsBuilder(id: "drop-test-events")
    .setJsCode("""
        if (payload.test_mode === true) {
            drop()
        }
    """)
    .setScope(.afterCollectors)

config.setTransformation(dropTestEvents)
```

```swift
// Read from the data layer and enrich the payload
let enrichFromDataLayer = JavaScriptTransformationSettingsBuilder(id: "enrich-user")
    .setJsCode("""
        var userId = dataLayer.get('user_id')
        if (userId) {
            payload.enriched_user_id = userId
        }
    """)
    .setScope(.afterCollectors)

config.setTransformation(enrichFromDataLayer)
```

**Builder methods:**

| Method | Description |
|---|---|
| `setJsCode(_ code: String)` | The JavaScript code string to execute against each dispatch |

## JavaScript Globals

The following globals are available inside the JavaScript code:

| Global | Description |
|---|---|
| `payload` | Mutable object representing the dispatch data. Modifications are reflected in the result. Set to `undefined` (via `drop()`) to drop the dispatch. |
| `scope` | String indicating the current dispatch scope: `"aftercollectors"` or the dispatcher ID (e.g. `"collect"`). |
| `track(event)` | Triggers a new SDK track call with the given event name. |
| `track(event, payload)` | Triggers a track call with extra data (second arg must be an object). |
| `track(event, type)` | Triggers a track call with a specific type string (e.g. `"view"`). |
| `track(event, type, payload)` | Triggers a track call with type and extra data. |
| `drop()` | Marks the dispatch for deletion — equivalent to setting `payload = undefined`. |
| `dataLayer.get(key)` | Returns the current value for `key` from the persistent data layer. |
| `dataLayer.getAll()` | Returns all entries in the persistent data layer as an object. |
| `dataLayer.put(key, value, expiry)` | Stores a value in the data layer. `expiry` is an `Expiry` constant. |
| `dataLayer.remove(key)` | Removes a key from the data layer. |
| `dataLayer.clear()` | Removes all entries from the data layer. |
| `console.log(...)` | Logs at the default level. Also available: `debug`, `info`, `warn`, `error`. |
| `Expiry.forever` | Expiry constant — never expires. |
| `Expiry.session` | Expiry constant — expires when the session ends. |
| `Expiry.untilRestart` | Expiry constant — expires on the next app launch. |

> **Note:** Calls to `track(...)` inside JS are suppressed if the current dispatch was itself triggered by a JS transformation, to prevent infinite recursion.

## JSON Configuration

```json
{
  "transformation_id": "add-platform",
  "transformer_id": "JavaScriptTransformer",
  "scope": "aftercollectors",
  "order": 1,
  "configuration": {
    "js_code": "payload.platform = 'ios'"
  }
}
```
