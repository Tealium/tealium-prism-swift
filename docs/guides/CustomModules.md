# Creating Custom Modules

This guide explains how to create custom modules for the Tealium Prism SDK. Custom modules allow you to extend the SDK's functionality with your own data collection, processing, or dispatching logic.

## Overview

There are two main approaches to creating custom modules:

1. **Using BasicModuleFactory** - For simple modules with standard initialization patterns (only one module instance, no custom dependencies)
2. **Implementing ModuleFactory** - For modules requiring custom dependencies or multiple instances

## Using BasicModuleFactory

The `BasicModuleFactory` is the recommended approach for most custom modules. It provides a standardized way to create modules that conform to the `BasicModule` protocol.

### Step 1: Create Your Custom Module

Your custom module must conform to `BasicModule`:

```swift
class MyCustomModule: BasicModule {
    let version = "1.0.0"
    let id = Self.moduleType

    @StateSubject([:])
    var moduleConfiguration: ObservableState<DataObject>

    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self._moduleConfiguration.value = moduleConfiguration

        // Validate required configuration
        guard let apiKey = moduleConfiguration.getDataItem(key: "apiKey")?.get(as: String.self),
              !apiKey.isEmpty else {
            return nil // Return nil if initialization fails
        }

        // Initialize your module with the provided configuration
    }

    static let moduleType: String = "MyCustomModule"
}
```

### Step 2: Create a Settings Builder (Optional)

For type-safe configuration, create a custom settings builder:

```swift
public class MyCustomModuleSettingsBuilder: ModuleSettingsBuilder {
    enum Keys {
        static let apiKey = "apiKey"
        static let timeout = "timeout"
    }

    /// Sets the API key for the custom module.
    ///
    /// - Parameter apiKey: The API key to use
    /// - Returns: The builder instance for method chaining
    public func setApiKey(_ apiKey: String) -> Self {
        _configurationObject.set(apiKey, key: Keys.apiKey)
        return self
    }

     /// Sets the timeout for network requests.
     ///
     /// - Parameter timeout: The timeout in seconds
     /// - Returns: The builder instance for method chaining
    public func setTimeout(_ timeout: Int) -> Self {
        _configurationObject.set(timeout, key: Keys.timeout)
        return self
    }
}
```

### Step 3: Add Factory Method to Modules Extension

Add a factory method to the `Modules` extension:

```swift
public extension Modules {
    static func myCustomModule(forcingSettings block: EnforcingSettings<MyCustomModuleSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<MyCustomModule>(
            moduleType: Modules.Types.myCustomModule,
            enforcedSettings: block?(MyCustomModuleSettingsBuilder()).build()
        )
    }
}
```

### Step 4: Register Your Module

Add your module to the Tealium configuration:

```swift
var config = TealiumConfig(
    account: "account",
    profile: "profile",
    environment: "dev"
)

// Add with default settings
config.addModule(Modules.myCustomModule())

// Or add with default settings 
// but require this module to be defined in the Local or Remote settings to be initialized
config.addModule(Modules.myCustomModule(forcingSettings: nil))

// Or configure with specific settings
config.addModule(Modules.myCustomModule(forcingSettings: { builder in
    builder.setApiKey("your-api-key")
           .setTimeout(30)
           .setEnabled(true)
}))
```

## Custom ModuleFactory Implementation

For modules that need custom dependencies, multiple instances, or complex initialization logic, implement the `ModuleFactory` protocol directly:

```swift
public class CustomModuleFactory: ModuleFactory {
    public let allowsMultipleInstances: Bool
    public let moduleType: String
    
    private let customDependency: SomeDependency
    
    public init(customDependency: SomeDependency, allowsMultipleInstances: Bool = false) {
        self.customDependency = customDependency
        self.allowsMultipleInstances = allowsMultipleInstances
        self.moduleType = "CustomModule"
    }
    
    public func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> CustomModule? {
        CustomModule(context: context, 
                    moduleConfiguration: moduleConfiguration,
                    customDependency: customDependency)
    }
    
    public func getEnforcedSettings() -> [DataObject] {
        // Return enforced settings if needed
        []
    }
}
```

## Sending Network Requests

Modules that need to talk to the network (most commonly custom `Dispatcher`s) do so through the `TealiumContext` they are initialized with. Two entry points are available, both already wired with the SDK's logging, tracing, retry, and interceptor logic:

- **`context.networkClient`** — the primary entry point for any non-standard request. Build a request with `RequestBuilder` and hand the builder to `sendRequest(_:completion:)`; the client builds it for you, logs the outcome, and always calls the completion (a malformed URL or build failure completes with `.failure(.unknown)` and returns an already-disposed `Disposable`). Request bodies are **uncompressed by default** — opt into gzip only for endpoints that support it, via `gzip()`.

  ```swift
  // Uncompressed POST (safe for arbitrary endpoints)
  let disposable = context.networkClient.sendRequest(
      RequestBuilder.makePOST(url: endpoint, json: payload)
          .header("Bearer \(token)", forField: "Authorization")
  ) { result in
      switch result {
      case .success(let response): // handle response
      case .failure(let error):    // handle error (including .cancelled on dispose)
      }
  }

  // Opt into gzip compression when the endpoint supports it
  _ = context.networkClient.sendRequest(
      RequestBuilder.makePOST(url: endpoint, json: payload).gzip()
  ) { _ in }
  ```

  You can also pass a fully-formed `URLRequest` to `sendRequest(_:completion:)` if you need complete control over the request.

- **`context.networkHelper`** — a convenience short-circuit for standard, **uncompressed** GET/POST requests. Use it when you don't need custom headers, compression, or a hand-built `URLRequest`. For gzip or any customized request, use `context.networkClient` with a `RequestBuilder` instead.

  ```swift
  _ = context.networkHelper.post(url: endpoint, body: payload) { result in
      // handle result
  }
  ```

Dispose the returned `Disposable` to cancel an in-flight request; the completion is then called with `.failure(.cancelled)`.

## Best Practices

- **Module Type Constants**: Define module type constants in `Modules.Types` for consistency
- **Validation**: Always validate required configuration in your module's initializer
- **Return nil**: Return `nil` from the initializer if required configuration is missing or invalid
- **Settings Builders**: Use `ModuleSettingsBuilder` subclasses for type-safe configuration
- **Documentation**: Document your module's configuration options and behavior

## Limitations of BasicModuleFactory

- Modules cannot be instantiated multiple times (`allowsMultipleInstances` is always `false`)
- No support for custom dependencies beyond `TealiumContext`
- Standard initialization pattern only

If you need these features, implement `ModuleFactory` directly.
