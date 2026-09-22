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

## Reaching Other Modules

A module reaches the other modules through the `ModuleManager` exposed on the `TealiumContext` as `context.moduleManager`.

These lookups are asynchronous, and there is deliberately no synchronous alternative, because of *when* a module is created. 
The modules of a settings pass are created one at a time, so when your `init` runs the module you are looking for may not exist yet. 
A synchronous answer at that point couldn't tell "that module is not enabled" from "that module hasn't been created yet", so instead of handing back a premature `nil`, these methods withhold the answer until the pass has created every module.

- **`getModule(completion:)`** — a one-shot lookup of a concrete module type, for when you need the module once, at a specific moment.

  ```swift
  context.moduleManager.getModule { (other: OtherCustomModule?) in
      // Called once, after the modules have been created
  }.addTo(disposer)
  ```

- **`observeModule(_:)`** — the same lookup, followed over time. Use it when the module can come and go: a settings update can enable or disable it, and each change is emitted.

  ```swift
  context.moduleManager.observeModule(OtherCustomModule.self)
      .subscribe { [weak self] other in self?.other = other }
      .addTo(disposer)
  ```

- **A transformation, with `observeModule(_:)`, `observeModules(_:)` or `getModule(transform:completion:)`** — the only way to reach a module you can't name as a concrete type: one that you only know through a protocol you declare, or one of several instances. The block is applied to every module in `ModuleSettings.order`; the single-module variants stop at the first one returning a non-`nil` value, while `observeModules` collects them all.

  ```swift
  class MyCustomModule: BasicModule {
      private var provider: MyDataProviding?
      private let disposer = Disposables.automatic()

      required init?(context: TealiumContext, moduleConfiguration: DataObject) {
          context.moduleManager.observeModule { $0 as? MyDataProviding }
              .subscribe { [weak self] provider in self?.provider = provider }
              .addTo(disposer)
      }
  }
  ```

Two behaviours are worth spelling out, as neither is visible from the signatures:

- Once one of these has started emitting, a `nil` (or an empty array) means **the module is not enabled**. It never means "not created yet".
- After the SDK has been shut down you get a `nil` (or an empty array) as well, rather than a lookup that never resolves.

The transformation variants re-emit only when the set of modules whose transformation succeeded changes, by identity or order. A value that varies over time for the same module is not re-emitted — observe it through the module itself.

Subscribe to all of these from the Tealium queue. Your module already runs on it, so inside a module there is nothing to do; to consume them from another queue, chain `subscribeOn(_:)` with the Tealium queue from `TealiumContext.queue` eventually followed by `observeOn(_:)` with yours.

## Sending Network Requests

Modules that need to talk to the network (most commonly custom `Dispatcher`s) do so through the `NetworkUtilities` exposed on the `TealiumContext` as `context.network`. Two entry points are available, both already wired with the SDK's logging, tracing, retry, and interceptor logic:

- **`context.network.networkClient`** — the primary entry point for any non-standard request. Build a request with `RequestBuilder` and hand the builder to `sendRequest(_:completion:)`; the client builds it for you, logs the outcome, and always calls the completion (a malformed URL or build failure completes with `.failure(.unknown)` and returns an already-disposed `Disposable`). Request bodies are **uncompressed by default** — opt into gzip only for endpoints that support it, via `gzip()`.

  ```swift
  // Uncompressed POST (safe for arbitrary endpoints)
  let disposable = context.network.networkClient.sendRequest(
      RequestBuilder.makePOST(url: endpoint, json: payload)
          .header("Bearer \(token)", forField: "Authorization")
  ) { result in
      switch result {
      case .success(let response): // handle response
      case .failure(let error):    // handle error (including .cancelled on dispose)
      }
  }

  // Opt into gzip compression when the endpoint supports it
  _ = context.network.networkClient.sendRequest(
      RequestBuilder.makePOST(url: endpoint, json: payload).gzip()
  ) { _ in }
  ```

  You can also pass a fully-formed `URLRequest` to `sendRequest(_:completion:)` if you need complete control over the request.

- **`context.network.networkHelper`** — a convenience short-circuit for standard, **uncompressed** GET/POST requests. Use it when you don't need custom headers, compression, or a hand-built `URLRequest`. For gzip or any customized request, use `context.network.networkClient` with a `RequestBuilder` instead.

  ```swift
  _ = context.network.networkHelper.post(url: endpoint, body: payload) { result in
      // handle result
  }
  ```

Dispose the returned `Disposable` to cancel an in-flight request; the completion is then called with `.failure(.cancelled)`.

## Best Practices

- **Module Type Constants**: Define module type constants in `Modules.Types` for consistency
- **Other Modules**: Never assume the other modules exist while your `init` runs — resolve them through `context.moduleManager`, which withholds the answer until the modules of the current settings pass have been created
- **Validation**: Always validate required configuration in your module's initializer
- **Return nil**: Return `nil` from the initializer if required configuration is missing or invalid
- **Settings Builders**: Use `ModuleSettingsBuilder` subclasses for type-safe configuration
- **Documentation**: Document your module's configuration options and behavior

## Limitations of BasicModuleFactory

- Modules cannot be instantiated multiple times (`allowsMultipleInstances` is always `false`)
- No support for custom dependencies beyond `TealiumContext`
- Standard initialization pattern only

If you need these features, implement `ModuleFactory` directly.
