# Changelog

All notable changes to Tealium Prism for Swift are documented in this file. Releases are published on [GitHub](https://github.com/Tealium/tealium-prism-swift/releases).

## 0.8.0 (Draft)

### Breaking Changes

#### Enums

- Public enums that may gain cases in future releases are now non-exhaustive ([SE-0487](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0487-extensible-enums.md) `@nonexhaustive`). With a Swift 6.2.3 or later compiler, a `switch` over one of them without an `@unknown default` case is an error in Swift 6 language mode and a warning in Swift 5 language mode. Add an `@unknown default` case so your code keeps compiling when a later release adds cases. Older compilers are unaffected. The non-exhaustive enums are:
  - Errors: `TealiumError`, `NetworkErrorType`, `ConversionError`, `JSONParsingError`, `DatabaseError`, `CommandError`, `ModuleError`, `LifecycleError` and `ContextAPIError`.
  - Others: `DispatchScope`, `TransformationScope`, `BarrierScope`, `NetworkConnection.ConnectionType`, `ContextAPIRegion`, `ExpiryPolicy`, `Expiry`, `UpdatePolicy` and `RetryPolicy`.
- A `switch` over `NetworkConnection` that matches the connection type (for example `case .connected(.wifi)`) also needs an `@unknown default` case, because `NetworkConnection.ConnectionType` is non-exhaustive. `NetworkConnection` itself is still exhaustive, so `case .connected:` without the nested match needs no change.

#### Commands

- `Dispatch.getCommands()` now returns command names normalized the same way `Command` names are registered: trimmed and lowercased. For example, `[" LogEvent ", "other"]` now returns `["logevent", "other"]`. The `command_name` value in the payload is unchanged. If you compare the returned names, compare them with lowercased names. Command logs and `CommandError.commandNotFound` errors also show the normalized name.

### Additions

- Made `DataObject.getConvertible(converter:)` public.
- Added `ComparableUtils.coerce(_:min:max:)` to clamp a value between a minimum and a maximum.
- Added a privacy manifest (`PrivacyInfo.xcprivacy`) to Core, declaring no tracking, no collected data and no required-reason APIs.

### Deprecations

- Deprecated `Observable.resubscribingWhile(_:)`. The SDK no longer uses it, and it will be removed in a future version.

### Improvements

- A corrupt database file is now deleted and recreated, and the reason is logged under the `Persistence` category. Before, every launch failed to open it and fell back to in-memory storage, so queued events, the visitor ID and the session weren't kept across launches. Only SQLite corruption errors trigger this: a file that can't be opened for any other reason, for example because Data Protection keeps it locked before the first unlock, is never deleted.
- Command names and the lenient boolean and number conversions, including numeric load rule conditions, now trim newlines as well as spaces and tabs, matching Kotlin. For example, `"log\n"` now runs the `log` command and `"true\n"` converts to `true`.
- `DispatchType(rawValue:)` is now case insensitive and maps `"link"` to `.event`.

### Fixes

- Fixed the dispatch loop stranding a batch of events when a barrier closed while the batch was being taken from the queue, most often the `BatchingBarrier`. Those events were never sent and kept using in-flight slots until the app was relaunched. Draining a large backlog also no longer recurses deeply on the stack.
- Fixed a `Dispatcher` with a `dispatchLimit` below 1 crashing the dispatch loop. It is now treated as 1.
- Fixed `DataLayer.onDataUpdated` and `DataLayer.onDataRemoved` reporting a key in both events when a transaction edited it more than once. Each key now appears in at most one event per transaction, matching its stored state: for example, a `put` followed by a `remove` is reported only in `onDataRemoved`.
- Fixed a `put` with an expiry that has already passed being reported in `onDataUpdated`, and a date before 1970 being stored as never expiring. Such a `put` now removes any existing value at that key and is reported in `onDataRemoved`.
- Fixed `Dispatch.getCommands()` returning names that are blank after trimming. A dispatch with only blank command names now logs "No command in dispatch" instead of failing each name with `CommandError.commandNotFound`.
- Fixed a fresh Swift Package Manager resolution picking SQLite.swift 0.17.0, which requires iOS 15, macOS 12 and watchOS 9 and fails to build against Prism's minimum OS versions. SQLite.swift is now constrained to 0.15.x, from 0.15.4, in both `Package.swift` and the podspec.

## [0.7.0](https://github.com/Tealium/tealium-prism-swift/releases/tag/0.7.0) - 2026-10-16 - General Availability

### Breaking Changes

#### Build

- Building the SDK now requires Xcode 16 (Swift 6.0 compiler) or later. `Package.swift` now uses `swift-tools-version:6.0`, while the sources keep compiling in Swift 5 language mode.

#### Modules

- Renamed `MomentsAPI` to `ContextAPI` everywhere:
  - SPM library `TealiumPrismMomentsAPI` → `TealiumPrismContextAPI` and CocoaPods subspec `MomentsAPI` → `ContextAPI`.
  - `MomentsAPI`, `MomentsAPIError`, `MomentsAPIRegion` and `MomentsAPISettingsBuilder` → `ContextAPI`, `ContextAPIError`, `ContextAPIRegion` and `ContextAPISettingsBuilder`.
  - `Modules.momentsAPI(forcingSettings:)` → `Modules.contextAPI(forcingSettings:)` and `Tealium.momentsAPI()` → `Tealium.contextAPI()`.
  - The module ID, and therefore the key used in local and remote settings, changed from `MomentsAPI` to `ContextAPI`.
- Moved visitor ID handling to the new `VisitorId` module (see Additions):
  - `Tealium.resetVisitorId()` → `Tealium.visitorId.regenerate()`.
  - `Tealium.clearStoredVisitorIds()` → `Tealium.visitorId.eraseLocalHistory()`.
  - `CoreSettingsBuilder.setVisitorIdentityKey(_:)` → `VisitorIdSettingsBuilder.setVisitorIdentityKey(_:)`. The `visitor_identity_key` setting moved from the `core` settings to the `VisitorId` module settings.
  - Removed `TealiumContext.visitorId`. Modules can get the visitor ID from the `VisitorId` module instead.
  - Renamed the `VisitorIdProvider` log category to `VisitorId`.
  - `ContextAPI` now depends on the `VisitorId` module and fails with `ModuleError.moduleNotEnabled` if that module is disabled.
- Removed the public consent integration API for now: `TealiumConfig.enableConsentIntegration(with:forcingConfiguration:)` and `TealiumConfig.cmpAdapter` are no longer available. Any `consent` section in local or remote settings is ignored, and the SDK logs this once.
- Renamed `DataLayer.put(data:expiry:)` to `DataLayer.putAll(dataObject:expiry:)`.
- `DataLayer.transactionally` now passes a single `DataStoreTransaction` to its block instead of the `apply`, `getDataItem` and `commit` closures, and the `DataLayer.Apply`, `DataLayer.Get` and `DataLayer.Commit` typealiases were removed. Make your edits on the transaction (`put`, `putAll`, `remove`, `clear`, `apply`), read already committed data with its getters, and call `try transaction.commit()` to apply the edits.
- `ModuleError.objectNotFound` was replaced by `ModuleError.tealiumError(TealiumError)`. A new `ModuleError.moduleShutdown` case is returned when a module is shut down while an operation is still pending.
- `ModuleManager.getModule(completion:)` now accepts an optional `transform` and returns a `Disposable`. On `ModuleProxy`, the `KeyPath` overload of `observeModule` was removed; use `observeModule(transform:)` instead.

#### Payload

- `tealium_session_id` is now expressed in epoch milliseconds instead of seconds. A session started before the update keeps its ID until it expires.
- Memory fields are now integers expressing whole megabytes instead of strings like `"42.00MB"`. This applies to `app_memory_usage`, `memory_active`, `memory_free`, `memory_inactive`, `memory_compressed`, `memory_wired` and `memory_physical`.

#### Mappings

- `Dispatcher` mappings are now applied on top of the full payload instead of building a new payload from scratch. Unmapped keys are kept, and a mapped destination replaces any existing value at that path. Mapped `command_name` values are the exception: they are appended to the existing commands.
- Removed `Mappings.keep(_:)` and `CommandMappingsBuilder.keep(_:)`, since keeping the original keys is now the default behavior.

#### Network

- `NetworkUtilities.networkClient` and `NetworkUtilities.networkHelper` now make a single attempt per request, with a default request timeout of 30 seconds. A module that needs retries should create its own client with `newClient(withAdditionalInterceptors:maxRetryCount:)` and then call `makeNetworkHelper()` on it if needed.
- Reworked `RequestInterceptor`. It now has two required methods: `onAttemptResult(_:retryCount:with:)` and `shouldRetry(_:consecutiveRetryCount:with:)`. They replace `didComplete(_:with:)`, `waitingForConnectivity(_:)` and `shouldRetry(_:retryCount:with:)`.
- Removed `NetworkConfiguration` and `InterceptorManagerProtocol` from the public API.

#### Transformers

- `Transformer.applyTransformation(_:to:scope:completion:)` now returns a `Disposable`, so an in-flight transformation can be cancelled. Transformers with nothing to cancel can return `Disposables.disposed()`. The threading and completion contract of this method is now documented.

### Additions

- Added the `VisitorId` module. It is added to every `Tealium` instance by default and can be configured with `Modules.visitorId(forcingSettings:)`. It is accessed through `Tealium.visitorId`, a `VisitorIdManager` that:
  - Is a `Subscribable` that emits the current visitor ID on subscription and every time it changes.
  - Exposes `current()`, `regenerate()` and `eraseLocalHistory()`.
- Added `RequestInterceptors.retryWithBackoff(maxAttempts:transientBaseDelay:throttlingBaseDelay:maxDelay:retryAfterAboveMaxDelay:)` and `RequestInterceptors.retryWhenConnected(connectivityManager:)`. Pass them to `NetworkClient.newClient(withAdditionalInterceptors:maxRetryCount:)` to add retries to a client. Retries use exponential backoff with jitter and treat the `Retry-After` header as a minimum wait.
- Added `NetworkClient.makeNetworkHelper()` to get a `NetworkHelperProtocol` backed by a custom client.
- Added `DataStoreTransaction`, the noncopyable transaction passed to `DataLayer.transactionally`, with the same read and write utilities as the `DataLayer`.
- Added `observeModules`, `observeModule` and `getModule(transform:completion:)` utilities to `ModuleManager`.
- Added `observeModuleResult(transform:)` to `ModuleProxy`. Unlike `observeModule`, it also emits failures, for example when the module is not enabled or when the instance is shut down.
- Added the `Persistence` log category.

### Improvements

- Enabled SQLite WAL mode. This greatly reduces disk writes and improves startup time. The log is checkpointed when the app goes to the background and when the instance is shut down.
- Added database upgrade support. A database that can't be opened, or that was created by a newer SDK version, is now deleted and recreated, and the reason is logged.
- Moved the stored visitor ID and identity associations into the `VisitorId` module storage with a database upgrade. Existing visitor IDs are preserved.
- Retries for remote settings and `ContextAPI` requests are now bounded. Settings requests retry up to 3 times with backoff and wait for connectivity; if they still fail, the next refresh is scheduled after a cooldown. `ContextAPI` requests retry up to 3 times with backoff.
- Made `DeviceDataModule` retry the device-names download, with backoff and waiting for connectivity. After a failure it tries again later in the same session, after a growing cooldown.
- Module lookups now wait until the settings have been applied, so a module that is about to be enabled is no longer treated as disabled during startup.
- Duplicate commands are now removed from `Dispatch.getCommands()`.

### Fixes

- Fixed `DeviceDataModule` adding the whole cached device-names file to every event when the device wasn't listed in it. The model info is now updated in the same session once a downloaded file includes the device.
- Fixed `DeviceDataModule` not enabling battery monitoring when a configuration update turns on battery reporting.
- Fixed deep links containing `tealium_trace_id` failing when handled on app launch, before modules were created.
- Fixed `regenerate()` linking the new visitor ID to an identity that had already been removed from the data layer.
- Fixed setting an existing array index through a `DataObject` path inserting a new element and shifting the others, instead of replacing the value.
- Fixed modules that are removed by a settings update, or replaced with a new instance in `updateConfiguration`, not being shut down. Shutting down a module no longer deletes its queued dispatches.
- Fixed disabled `Dispatcher`s being kept in memory by the `DispatchManager`, and a case where the dispatch loop could run twice for the same `Dispatcher` and exceed its inflight limit.
- Fixed `TealiumInstanceManager` so that a pending shutdown completes before a new instance with the same key is created. `Tealium.shutdown()` no longer affects a newer instance created with the same key.

## [0.6.0](https://github.com/Tealium/tealium-prism-swift/releases/tag/0.6.0) - 2026-08-28

### Breaking Changes

- `TealiumInstanceManager` now holds a strong reference to each `Tealium` instance. As a result, you must explicitly call `Tealium.shutdown` to tear down an instance. Once shut down, an instance can no longer be used; any subsequent call fails with a `TealiumError.instanceShutdown` error.
- Removed the default gzip behavior from `NetworkHelperProtocol`. To gzip a payload, use the `NetworkClient` directly and pass a `RequestBuilder` configured with `gzip(true)`.
- Changed the error type returned by `NetworkClient` and `NetworkHelperProtocol`. `NetworkError` is now a struct wrapping a `NetworkErrorType` enum and the `HTTPURLResponse` returned by the server, when available. When multiple errors occur, a non-200 response error now takes precedence over any `URLError` or parsing error.
- Aligned the `TealiumContext` API with Kotlin. This includes:
  - Removing `NetworkHelperProtocol`, `NetworkClient`, and `ConnectivityManagerProtocol` in favor of a single `NetworkUtilities` container that exposes all three.
  - Renaming `modulesManager: ModulesManager` to `moduleManager: ModuleManager`.
  - Renaming `activityListener` to `applicationStatusListener`.
  - Removing `databaseProvider`.
- `CMPAdapter` implementations now have a documented threading contract: emit consent decisions from a single thread, and apply `subscribeOn` to the returned `Observable` with a queue backed by that same thread. Emitting from anywhere else races.

### Additions

- Added support for multiple `Failure` types in `Single.toAsync`, making it easier to use with our own async module operations.
- Added `Template` and `TemplateProcessor` utilities for reuse in future `Module`s.
- Added the `observeModules` utility to `ModuleProxy`.
- Added public APIs on `DataItem` for converting to and from JSON.
- Made `RequestBuilder` public, allowing easy creation of `URLRequest` objects for use with the `NetworkClient`.
- Added the `getCommands` utility method to `Dispatch`.

### Improvements

- Made visitor ID creation lowercase to align with Kotlin. Previously created visitor IDs are left untouched.
- Added the `request_uuid` field to the event payload by default.
- Made `LifecycleEvent` case insensitive.
- Made `ApplicationStatusListener` avoid blocking the main thread when notifications are posted.
- Aligned `SQLiteOpenHelper` behavior with the Android reference implementation. Database upgrades now run only when an app that already has a database on disk is upgraded.
- Improved network request logs to surface errors more clearly.

### Fixes

- Fixed a `DeviceDataModule` race condition and avoided a main-thread hop when both battery and screen reporting are disabled.
- Fixed a potential retain cycle when a `Dispatcher` holds a reference to the `TealiumContext`. No current `Dispatcher` had this issue, but future `Dispatcher`s might have.
- Fixed the dispatch chain to support completions that each cover a subset of dispatches. Before if a `Dispatcher` was completing an array of `Dispatch`es in separate batches, the batches after the first one wouldn't be properly deleted from disk.
- Fixed thread safety in `Observable.subscribeOn` and `Observable.observeOn`. Now they can be properly used, as long as we subscribe on the emitting queue and we observe on a different queue immediately after.
- Fixed a potential hang in `Single.toAsync` where the async method would never return if the `Subscribable` completed without emitting a value.

## [0.5.0](https://github.com/Tealium/tealium-prism-swift/releases/tag/0.5.0) - 2026-05-28

### Breaking Changes

#### Settings

- `BarrierScope` and `TransformationScope` `dispatcher` case renamed to plural form (`.dispatcher` → `.dispatchers`) and accepts an array of Dispatcher IDs.
  - `BarrierScope.dispatchers(["Dispatcher1", "Dispatcher2"])`.
  - `TransformationScope.dispatchers(["Dispatcher1", "Dispatcher2"])`.
- Made `BarrierScope` and `TransformationScope` singular in the respective `BarrierSettings` and `TransformationSettings`.
- `TealiumConfig.setTransformation(_:)` now accepts a `TransformationSettingsBuilder` directly instead of a built `TransformationSettings`. Remove any `.build()` call at the call site.
- `app_memory_usage` moved to the `AppData` module (always available, no longer requires `DeviceData`).

#### DataObject & DataItem

- `DataObject` initializers no longer accept optional values. Pass non-optional `DataInput` values directly, or use the new `DataObject(compacting:)` initializer to filter nils.
- `DataItem` changed from `class` → `struct`.
- `DataItem(serializing:)` initializer renamed to `DataItem(jsonValue:)`.

#### PubSub

- `Disposable` now requires `AnyObject`.
- `Disposables.automaticComposite()` → `Disposables.automatic()`
- `Disposables.subscription(unsubscribe:)` → `Disposables.subscription(onDispose:)`. Parameter renamed and default value removed.
- Removed `Publisher` protocol, you can now use `Subject` instead.
- `Subject` now is both an `Observable` and an `Observer`.
  - To emit new events you can use `onNext` instead of `publish`.
  - `StateSubject` and `ReplaySubject` `publishIfChanged(_:)` renamed to `onNextIfChanged(_:)`
  - Calling `onComplete` on a `Subject` completes it and prevents further `onNext` calls from emitting events.
- `Subscribable` no longer inherits from `ObservableConvertible`
  - Removed `asObservable` from `Subscribable`. This was not intended to be exposed and could have made the returned `Observable` non thread safe when used improperly.
- `Single` is now a concrete type rather than a protocol, to avoid overuse of existential types.

### Added

#### New Modules

- `TealiumPrismExtensions` module, including:
  - `Lowercase`: converts string values in the dispatch payload to lowercase.
  - `SetDataValues`: copies values between keys or sets constant values in the dispatch payload.
  - `PersistDataValue`: stores a value from the dispatch payload (or a constant) into the data layer with a configurable expiry and update policy.
- `TealiumJavaScriptExtension` module, to perform user defined JavaScript powered transformations.

#### Settings

- `TransformationSettings` gains an `order: Int` property (default `Int.max`); lower values run first when multiple transformations share the same scope.

#### DataObject & DataItem

- `DataObject(jsonObject:)` new initializer to build a `DataObject` from a `[String: Any]` JSON-serializable dictionary.
- `DataObject(jsonString:)` new initializer that parses a raw JSON string.
- `DataItem.null`: new static property for an explicit `NSNull`-containing item.

#### PubSub

- `Tealium.createDisposable` can be used to create a composite `Disposable` that is safe to group `Disposable`s from that specific `Tealium` instance.
- `Subscribable.subscribe` and `Observable.subscribe` now accept a typed `Observer` which implements `onNext` and `onComplete`.
  - You can still call subscribe with anonymous callbacks instead.
- `Observables.callback(from:)` gains a new overload that accepts a function returning a `Disposable` (for cancellable async calls)

#### Commands

- `Command` functionality, that will be used when writing modules that will be commanded by some tracking events (the modules that were previously known as `RemoteCommands`). Includes:
  - `Command`, `SyncCommand`, `CommandDispatcher`, `CommandName`, `CommandMappingsBuilder`, and `CommandError`

### Fixed

- Fixed `Observable` operators and subjects delivering events to observers that had already been disposed.

**Full Changelog**: https://github.com/Tealium/tealium-prism-swift/compare/0.4.0...0.5.0

## [0.4.0](https://github.com/Tealium/tealium-prism-swift/releases/tag/0.4.0) - 2026-02-19

### Breaking Changes

- Changed barrier configuration methods to support their programmatic configuration.
- Changed the way `Mappings` are programmatically set on `DispatcherSettingsBuilder`. Before the builder was accepting an array of `Mappings` that could be created from static methods, now it accepts a callback with a mappings builder. This allows each specific `Dispatcher` to create their own mappings methods, to make mappings less error prone.
- Changed shared `DataStorage` ID from `core` to `shared` and use the same `DataStorage` for the `VisitorStorage` as well (which was using the `visitor` ID). Old cached items will be lost but will be cached again on next download.

### Added

- Added programmatic `Barrier` configuration.
- Some utility `LenientConverters` that can be used in `Dispatcher`s to extract data from the payload that could be either of the supported primitive types.

### Changed

- `Mappings` now support mapping constants of any supported `DataInput`, instead of just `Strings`.

### Fixed

- An issue where `DataItem.get(as: Int.self)` were returning 0 if that `DataItem` contained any floating point `NotANumber`. Now correctly returns nil.

## [0.3.0](https://github.com/Tealium/tealium-prism-swift/releases/tag/0.3.0) - 2026-01-22

### First Early Access Release

The new TealiumPrism for Swift is out for Early Access, including:

#### TealiumPrismCore

The main library, with powerful features like:

- **Tracking** events to potentially multiple Dispatchers
- **Enriching** events with data coming from multiple Collectors
- **Transformations** to transform or drop events before reaching each Dispatcher
- **LoadRules** to only send specific events to each Dispatcher
- **Barriers** to halt or delay events from reaching each Dispatcher
- Fully **modular**, customizable and **remotely configurable** architecture

It comes with a series of baked in Modules:

- **AppData**: to enrich events with Application data
- **Collect**: to send events to the Tealium platform to process
- **ConnectivityData**: to enrich events with Connectivity data
- **DataLayer**: to save and enrich events with user provided data
- **DeepLink**: to enrich events with DeepLink data
- **DeviceData**: to enrich events with Device data
- **TealiumData**: to enrich events with information regarding the Tealium account
- **TimeData**: to enrich events with relevant Time data
- **Trace**: to manage a Trace to easily debug the library integration

#### TealiumPrismLifecycle

An additional module that can be added to automatically track information like count of application launches, time spent in foreground, time since last visit and similar.

#### TealiumPrismMomentsAPI

An additional module that can be added to retrieve information about the visitor profile from Audience Stream.
