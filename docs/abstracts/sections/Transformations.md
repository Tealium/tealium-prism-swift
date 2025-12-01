Transformations provide a powerful way to modify, enrich, or filter dispatches in the Tealium SDK before they are sent to dispatchers. They allow you to implement custom business logic that transforms your data based on specific conditions and scopes.

## Overview

The transformation system consists of several key components:

- **`Transformer`**: Modules that implement the actual transformation logic
- **`TransformationSettings`**: Configuration that defines when and how transformations are applied
- **`TransformationScope`**: Defines where in the dispatch pipeline transformations occur
- **`Mappings`**: A specialized transformation system for remapping dispatch data

Transformations are evaluated and applied at different points in the dispatch lifecycle, allowing you to modify data after collection or before sending to specific dispatchers.

## Basic Concepts

### Transformation Scopes

Transformations can be applied at different points in the dispatch pipeline:

```swift
// Apply after data collection, before any dispatchers
TransformationScope.afterCollectors

// Apply to all dispatchers
TransformationScope.allDispatchers  

// Apply only to a specific dispatcher
TransformationScope.dispatcher(id: "my_dispatcher")
```

### Transformation Settings

A `TransformationSettings` defines when and how a transformation should be applied:

```swift
let transformation = TransformationSettings(
    id: "my_transformation",
    transformerId: "my_transformer", 
    scopes: [.allDispatchers],
    configuration: ["key": "value"],
    conditions: .just(Condition.equals(ignoreCase: false, 
                                      variable: "event_type", 
                                      target: "purchase"))
)
```

## Creating Custom Transformers

### Implementing the Transformer Protocol

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
            // Add transformation data to the dispatch
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
// Create a factory for your transformer
// Can be defined inside MyCustomTransformer class or separately
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

## Transformation Configuration

### Programmatic Configuration

```swift
// Create transformation settings
let enrichmentTransformation = TransformationSettings(
    id: "user_enrichment",
    transformerId: "DataEnrichmentTransformer",
    scopes: [.afterCollectors],
    configuration: [
        "enable_enrichment": true,
        "enrichment_type": "user_data",
        "source": "user_profile"
    ],
    conditions: .just(Condition.isDefined(variable: "user_id"))
)

// Add to configuration
config.setTransformation(enrichmentTransformation)
```

### JSON Configuration

Transformations can also be defined in JSON format for remote configuration:

```json
{
  "transformation_id": "user_enrichment",
  "transformer_id": "MyCustomTransformer", 
  "scopes": ["aftercollectors"],
  "configuration": {
    "enable_enrichment": true,
    "enrichment_type": "user_data",
    "source": "user_profile"
  },
  "conditions": {
    "operator": "defined",
    "variable": {"key": "user_id"}
  }
}
```

## Common Transformation Patterns

### Data Enrichment

Add additional data to dispatches based on existing values:

```swift
class DataEnrichmentTransformer: Transformer {
    static let moduleType = "DataEnrichmentTransformer"
    var id: String { Self.moduleType }
    let version: String = "1.0.0"
    
    func applyTransformation(_ transformation: TransformationSettings,
                           to dispatch: Dispatch,
                           scope: DispatchScope,
                           completion: @escaping (Dispatch?) -> Void) {
        
        var enrichedDispatch = dispatch
        
        // Add timestamp
        enrichedDispatch.enrich(data: ["enriched_at": Date().timeIntervalSince1970])
        
        // Add user segment based on purchase amount
        if let amount = dispatch.payload.get(key: "purchase_amount", as: Double.self) {
            let segment = amount > 100 ? "high_value" : "standard"
            enrichedDispatch.enrich(data: ["user_segment": segment])
        }
        
        completion(enrichedDispatch)
    }
}
```

### Data Filtering

Filter out sensitive or unwanted data:

```swift
class DataFilterTransformer: Transformer {
    static let moduleType = "DataFilterTransformer"
    var id: String { Self.moduleType }
    let version: String = "1.0.0"
    
    func applyTransformation(_ transformation: TransformationSettings,
                           to dispatch: Dispatch,
                           scope: DispatchScope,
                           completion: @escaping (Dispatch?) -> Void) {
        
        let sensitiveKeys = transformation.configuration
            .getArray(key: "sensitive_keys", of: String.self)?
            .compactMap { $0 } ?? []
        
        var filteredDispatch = dispatch
        
        // Remove sensitive data - create new payload without sensitive keys
        var newPayload = DataObject()
        for (key, value) in filteredDispatch.payload.asDictionary() {
            if !sensitiveKeys.contains(key) {
                newPayload.set(value, key: key)
            }
        }
        filteredDispatch.replace(payload: newPayload)
        
        completion(filteredDispatch)
    }
}
```

### Conditional Dispatch Dropping

Drop dispatches based on specific conditions:

```swift
class ConditionalDropTransformer: Transformer {
    static let moduleType = "ConditionalDropTransformer"
    var id: String { Self.moduleType }
    let version: String = "1.0.0"
    
    func applyTransformation(_ transformation: TransformationSettings,
                           to dispatch: Dispatch,
                           scope: DispatchScope,
                           completion: @escaping (Dispatch?) -> Void) {
        
        // Drop test events in production
        let isTestEvent = dispatch.payload.get(key: "test_mode", as: Bool.self) == true
        let isProduction = transformation.configuration.get(key: "environment", as: String.self) == "production"
        
        if isTestEvent && isProduction {
            // Drop the dispatch
            completion(nil)
        } else {
            // Keep the dispatch
            completion(dispatch)
        }
    }
}
```

## Advanced Transformation Features

### Conditional Transformations

Use conditions to control when transformations are applied:

```swift
// Only apply to purchase events from premium users
let conditions = Rule.and([
    .just(Condition.equals(ignoreCase: false, variable: "event_type", target: "purchase")),
    .just(Condition.equals(ignoreCase: false, variable: "user_tier", target: "premium"))
])

let transformation = TransformationSettings(
    id: "premium_purchase_enrichment",
    transformerId: "DataEnrichmentTransformer",
    scopes: [.allDispatchers],
    conditions: conditions
)
```

### Scope-Specific Transformations

Apply different transformations at different pipeline stages:

```swift
// Enrich data after collection
let enrichmentTransformation = TransformationSettings(
    id: "data_enrichment",
    transformerId: "DataEnrichmentTransformer",
    scopes: [.afterCollectors]
)

// Filter data for specific dispatcher
let filterTransformation = TransformationSettings(
    id: "sensitive_data_filter", 
    transformerId: "DataFilterTransformer",
    scopes: [.dispatcher(id: "external_analytics")]
)
```

### Transformation Identity and Multiplicity

Each transformation is uniquely identified by its `id` field within the `TransformationSettings`. This ID serves as the primary identifier for the transformation and must be unique across all transformations in the system.

**Important**: A single `Transformer` can handle multiple different transformations. The relationship is not 1-to-1 - one transformer can provide many different transformation behaviors, each identified by a unique transformation ID.

```swift
class MultiPurposeTransformer: Transformer {
    static let moduleType = "MultiPurposeTransformer"
    var id: String { Self.moduleType }
    let version: String = "1.0.0"

    func applyTransformation(_ transformation: TransformationSettings,
                           to dispatch: Dispatch,
                           scope: DispatchScope,
                           completion: @escaping (Dispatch?) -> Void) {

        // Use the transformation ID to determine which transformation to apply
        switch transformation.id {
        case "user_enrichment":
            applyUserEnrichment(dispatch, completion)

        case "data_validation":
            applyDataValidation(dispatch, completion)

        case "privacy_filter":
            applyPrivacyFilter(dispatch, completion)

        default:
            // Unknown transformation ID - pass through unchanged
            completion(dispatch)
        }
    }

    private func applyUserEnrichment(_ dispatch: Dispatch, _ completion: @escaping (Dispatch?) -> Void) {
        // Implementation for user enrichment transformation
        var enrichedDispatch = dispatch
        enrichedDispatch.enrich(data: ["enriched_by": "user_enrichment"])
        completion(enrichedDispatch)
    }

    private func applyDataValidation(_ dispatch: Dispatch, _ completion: @escaping (Dispatch?) -> Void) {
        // Implementation for data validation transformation
        let isValid = validateDispatchData(dispatch)
        completion(isValid ? dispatch : nil)
    }

    private func applyPrivacyFilter(_ dispatch: Dispatch, _ completion: @escaping (Dispatch?) -> Void) {
        // Implementation for privacy filtering transformation
        let filteredDispatch = removePrivateData(dispatch)
        completion(filteredDispatch)
    }

    private func validateDispatchData(_ dispatch: Dispatch) -> Bool {
        // Validation logic
        return true
    }

    private func removePrivateData(_ dispatch: Dispatch) -> Dispatch {
        // Privacy filtering logic
        return dispatch
    }
}
```

#### Multiple Transformations Configuration

You can configure multiple transformations that use the same transformer but perform different operations:

```swift
// All these transformations use the same transformer but have unique IDs
let userEnrichment = TransformationSettings(
    id: "user_enrichment",                    // Unique ID
    transformerId: "MultiPurposeTransformer", // Same transformer
    scopes: [.afterCollectors]
)

let dataValidation = TransformationSettings(
    id: "data_validation",                    // Different unique ID
    transformerId: "MultiPurposeTransformer", // Same transformer
    scopes: [.allDispatchers]
)

let privacyFilter = TransformationSettings(
    id: "privacy_filter",                     // Another unique ID
    transformerId: "MultiPurposeTransformer", // Same transformer
    scopes: [.dispatcher(id: "ExternalAnalytics")]
)
```

This design allows for:
- **Code reuse**: One transformer can handle related transformation logic
- **Flexible configuration**: Each transformation can have different scopes, conditions, and configurations
- **Clear separation**: Each transformation has a unique identity and purpose
- **Maintainability**: Related transformation functions are grouped in a single transformer class

## Data Mappings vs. Transformations

The SDK provides a specialized transformation system for remapping dispatch data using the `Mappings` API.

**Important**: Mappings are **not** implemented as transformations via a transformer, and they are only relevant to `Dispatcher`s. i.e. even if a `Module`/`Collector` has the `mappings` key populated in its config, the mappings wouldn't be evaluated unless the module implementation was an implementation of `Dispatcher`.

### Basic Mappings

```swift
// Simple key-to-key mapping
let mappings = [
    Mappings.from("source_key", to: "destination_key"),
    Mappings.keep("unchanged_key")
]
```

### Nested Data Mappings

```swift
// Map from nested objects
let mappings = [
    Mappings.from(JSONPath["user"]["profile"]["name"], to: "user_name"),
    Mappings.from(JSONPath["order"]["items"][0]["price"], to: "first_item_price")
]
```

### Conditional Mappings

```swift
// Only map if value matches condition
let mappings = [
    Mappings.from("user_type", to: "segment")
        .ifValueEquals("premium"),
    
    Mappings.constant("vip_user", to: "user_status")
        .ifValueIn("purchase_amount", equals: "1000")
]
```

### Configuring Mappings

```swift
// Add mappings to a dispatcher configuration (the Collect module in this case)
config.addModule(Modules.collect(forcingSettings: { enforcedSettings in
    enforcedSettings.setMappings(mappings)
}))
```

## Error Handling

### Transformation Errors

When transformations encounter errors, they need to be handled internally and either complete with the original dispatch or with nil to drop it:

```swift
func applyTransformation(_ transformation: TransformationSettings,
                       to dispatch: Dispatch,
                       scope: DispatchScope,
                       completion: @escaping (Dispatch?) -> Void) {
    
    do {
        // Attempt transformation
        let result = try performTransformation(dispatch, transformation)
        completion(result)
    } catch {
        // Log error and decide whether to pass through original dispatch or drop it
        print("Transformation failed: \(error)")
        
        // Option 1: Pass through original dispatch
        completion(dispatch)
        
        // Option 2: Drop the dispatch entirely
        // completion(nil)
    }
}
```

### Condition Evaluation Errors

If transformation conditions fail to evaluate, the transformation is skipped and the error is logged. This ensures the dispatch pipeline continues to function even when individual transformations encounter issues.

## Performance Considerations

### Transformation Order

Transformations are applied in the order they are defined. Consider the performance impact of your transformation order:

```swift
// Put lightweight transformations first
let transformations = [
    quickFilterTransformation,
    expensiveEnrichmentTransformation
]
```

### Asynchronous Operations

For transformations that require asynchronous operations:

```swift
func applyTransformation(_ transformation: TransformationSettings,
                       to dispatch: Dispatch,
                       scope: DispatchScope,
                       completion: @escaping (Dispatch?) -> Void) {
    
    // Perform async operation using Tealium queue for the callback
    fetchUserData(userId: dispatch.payload.get(key: "user_id", as: String.self)) { userData in
        TealiumQueue.worker.ensureOnQueue {
            var enrichedDispatch = dispatch
            enrichedDispatch.enrich(data: userData)
            completion(enrichedDispatch)
        }
    }
}
```

## Best Practices

### 1. Use Descriptive IDs

```swift
// Good
TransformationSettings(id: "user_profile_enrichment", ...)

// Avoid  
TransformationSettings(id: "transform1", ...)
```

### 2. Implement Proper Error Handling

```swift
func applyTransformation(_ transformation: TransformationSettings,
                       to dispatch: Dispatch,
                       scope: DispatchScope,
                       completion: @escaping (Dispatch?) -> Void) {
    
    guard let requiredValue = dispatch.payload.get(key: "required_field", as: String.self) else {
        // Log warning and pass through
        completion(dispatch)
        return
    }
    
    // Continue with transformation
    // ...
}
```

### 3. Use Conditions Effectively

```swift
// Check for required data before applying expensive transformations
let conditions = Rule.and([
    .just(Condition.isDefined(variable: "user_id")),
    .just(Condition.isNotEmpty(variable: "user_id")),
    .just(Condition.equals(ignoreCase: false, variable: "event_type", target: "purchase"))
])
```

### 4. Keep Transformations Focused

Create specific transformers for specific purposes rather than one large transformer that does everything.

## Dynamic Transformation Management

### Runtime Registration

Your modules can register and unregister transformations at runtime using the `TransformerRegistry`:

```swift
// Get the transformer registry from `TealiumContext`
let registry = context.transformerRegistry

// Register a new transformation
let newTransformation = TransformationSettings(
    id: "runtime_transformation",
    transformerId: "MyCustomTransformer",
    scopes: [.allDispatchers]
)
registry.registerTransformation(newTransformation)

// Unregister when no longer needed
registry.unregisterTransformation(newTransformation)
```

## Conclusion

Transformations provide a flexible and powerful way to customize how your analytics data is processed and sent to different destinations. By implementing custom transformers and configuring transformation settings appropriately, you can ensure your data meets the specific requirements of each analytics platform while maintaining clean separation of concerns in your codebase.
