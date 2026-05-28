Transformations modify, enrich, or filter dispatch payloads at specific points in the dispatch pipeline before they are sent to dispatchers. Each transformation is configured with a scope, an optional execution order, and optional conditions that control when it applies.

## Available Transformations

The SDK provides four built-in transformations:

| Transformation | Library | Description |
|---|---|---|
| SetDataValues | `TealiumPrismExtensions` | Copy values between keys or set constants in the payload |
| PersistDataValue | `TealiumPrismExtensions` | Persist a value to the data layer with expiry and update policies |
| Lowercase | `TealiumPrismExtensions` | Convert string values in the payload to lowercase |
| JavaScript | `TealiumPrismJavaScriptTransformer` | Execute JavaScript code against the payload (**not available on watchOS**) |

## Scopes

All transformations share a `setScope(_:)` method. Three scopes are available:

| Scope | When it runs |
|---|---|
| `.afterCollectors` | After all collectors have run, before the consent check and dispatch queues |
| `.allDispatchers` | Just before a dispatch is sent to every registered dispatcher |
| `.dispatchers(["id1", "id2", ...])` | Just before a dispatch is sent to the listed dispatchers only |

**JSON representation:**

| Scope | JSON value |
|---|---|
| `.afterCollectors` | `"scope": "aftercollectors"` |
| `.allDispatchers` | `"scope": "alldispatchers"` |
| `.dispatchers([...])` | `"scope": ["Collect", "Trace"]` (array of dispatcher IDs) |

## Ordering

Transformations within the same scope are sorted by their `order` value before execution. Lower values run first. Transformations without an explicit order default to `Int.max` and run last.

```swift
config.setTransformation(
    LowercaseSettingsBuilder(id: "normalize")
        .lowercaseAllVariables()
        .setScope(.afterCollectors)
        .setOrder(10)   // runs before order: 100
)
```

## Conditions

All transformations support an optional `setConditions(_:)` method that controls whether the transformation applies to a given dispatch:

```swift
config.setTransformation(
    SetDataValuesSettingsBuilder(id: "tag-purchase")
        .setConstant("high_value", to: .key("user_segment"))
        .setScope(.afterCollectors)
        .setConditions(.just(Condition.equals(ignoreCase: true,
                                              variable: "event_name",
                                              target: "purchase")))
)
```

## Adding Transformations

Pass any settings builder directly to `TealiumConfig.setTransformation(_:)`:

```swift
config.setTransformation(
    SetDataValuesSettingsBuilder(id: "copy-email")
        .setFrom(.key("raw_email"), to: .key("email"))
        .setScope(.afterCollectors)
)
```

Setting a transformation whose `(transformerId, id)` composite key matches an existing entry replaces it.

## Custom Transformers

To create a custom transformer, implement the `Transformer` protocol:

```swift
class MyCustomTransformer: Transformer {
    static let moduleType = "MyCustomTransformer"
    var id: String { Self.moduleType }
    let version: String = "1.0.0"
    
    func applyTransformation(_ transformation: TransformationSettings,
                           to dispatch: Dispatch,
                           scope: DispatchScope,
                           completion: @escaping (Dispatch?) -> Void) {
        // Access transformation configuration
        let enableEnrichment: Bool = transformation.configuration.get(key: "enable_enrichment") ?? true
        // Modify the dispatch
        var modifiedDispatch = dispatch
        if enableEnrichment {
            modifiedDispatch.enrich(data: ["transformed": "true"])
        }
        // Return the modified dispatch
        completion(modifiedDispatch)
        // Or return nil to drop the dispatch entirely
        // completion(nil)
    }
}
```

### Registering Your Transformer

Register your transformer with the SDK by creating a factory:

```swift
class MyCustomTransformerFactory: ModuleFactory {
    typealias SpecificModule = MyCustomTransformer
    var allowsMultipleInstances: Bool { false }
    var moduleType: String { MyCustomTransformer.moduleType }
    
    func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> MyCustomTransformer? {
        MyCustomTransformer()
    }
}
```

Then during SDK initialization:

```swift
// Add it to your Tealium configuration
config.addModule(MyCustomTransformerFactory())
```
