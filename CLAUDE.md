# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

Tealium Prism is a Swift SDK for integrating the Tealium CDP into iOS, macOS, tvOS, and watchOS apps. Minimum OS versions: iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 7.0. Swift tools version 5.5.

## Commands

### Setup
```bash
bundle install                    # Install Ruby dependencies (Fastlane, CocoaPods, Jazzy)
cd Example && pod install         # Install CocoaPods for Example project
```

### Testing
Run all tests before opening a PR:
```bash
./scripts/test_all.sh
```

Run tests for a specific platform:
```bash
./scripts/test_all.sh --platform iOS
```

Run a specific test scheme:
```bash
./scripts/run_tests.sh --scheme CoreTests_iOS --destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

Available test schemes (each with `_iOS`, `_tvOS`, `_macOS`, `_watchOS` suffixes):
- `CoreTests`, `EndToEndTests`, `LifecycleTests`, `MomentsAPITests`, `ExtensionsTests`
- `JavaScriptTransformerTests` (`_iOS`, `_tvOS`, `_macOS` only — unavailable on watchOS)
- iOS-only: `DelegateProxyTests_iOS`

Run a single test class via xcodebuild:
```bash
xcodebuild test -workspace Example/tealium-prism.xcworkspace \
  -scheme CoreTests_iOS \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:CoreTests_iOS/DispatchManagerTests
```

Tests use Fastlane `scan` under the hood (`skip_build: true`, derived data in `./build`).

### Linting
```bash
./scripts/lint.sh --config_file .swiftlint.yml       # Source code
./scripts/lint.sh --config_file .swiftlint_test.yml   # Test code
```

### Documentation
```bash
./scripts/docs.sh
```

## Architecture

### Module Structure
Five modules in `tealium-prism/`:

| Module | Role | Description |
|--------|------|-------------|
| **core/** | Foundation | Tracking, dispatching, persistence, module management, reactive system |
| **extensions/** | Transformers | SetDataValues, PersistDataValue, Lowercase transformers |
| **jstransformer/** | Transformer | JavaScript-based payload transformation (unavailable on watchOS) |
| **lifecycle/** | Collector | App lifecycle events (launch, wake, sleep) with crash/update detection |
| **momentsapi/** | Module | Visitor profile data from Tealium AudienceStream |

Each module has `API/` (public interfaces), `Internal/` (implementation), and `ObjC/` (Objective-C bridging) directories.

### Plugin System
Module protocol hierarchy:
- `Module` - Base with versioning, configuration, lifecycle. `BasicModule` adds `init?(context:moduleConfiguration:)`
- `Collector` (`Module`) - Enriches event payloads via `collect(_ dispatchContext:) -> DataObject`
- `Dispatcher` (`Module`) - Sends events via `dispatch(_ data:completion:)`, has `dispatchLimit` (default 1)
- `Transformer` (`Module`) - Applies transformations via `applyTransformation(_:to:scope:completion:)`

Modules are registered via `ModuleFactory` instances passed to `TealiumConfig.addModule()`. `ModulesManager` handles instantiation, configuration updates, and shutdown. Non-multi-instance modules are deduplicated.

### Built-in Modules (core/)
**Collectors:** AppData, DeviceData, TimeData, ConnectivityData, TealiumData, DataLayer (also a DataStore)
**Dispatchers:** Collect (batches up to 10, groups by visitorId), Trace (debugging)
**Other:** DeepLink

### Event Pipeline
```
track() → TrackerImpl
  → Collectors run in series (filtered by LoadRules)
  → TransformerCoordinator (afterCollectors scope)
  → ConsentManager check (drop if "tealium" purpose blocked)
  → QueueManager (SQLite-backed, per-dispatcher queues)
  → BarrierCoordinator check (open/closed per dispatcher)
  → TransformerCoordinator (dispatcher-specific scope)
  → Dispatcher.dispatch() (max 50 inflight per dispatcher)
  → Completion → remove from queue
```

Key classes: `TrackerImpl`, `DispatchManager`, `QueueManager`, `BarrierCoordinator`, `TransformerCoordinator`.

### Data Types
- `DataObject` - Dictionary wrapper `[String: DataInput]` with deep merging, path building, literal syntax
- `DataItem` - Lazy JSON value wrapper with typed getters: `get<T>()`, `getArray()`, `getDataDictionary()`
- `Dispatch` - Tracking event with `payload`, `id`, `timestamp`. Created with name, type (event/view), and optional data

### Configuration & Settings
**TealiumConfig** is the public builder. Key properties: `account`, `profile`, `environment`, `dataSource`, `settingsFile`, `settingsUrl`, `modules`, `barriers`, `loggerType`.

**Settings merge priority** (lowest to highest):
1. Local JSON (`settingsFile`)
2. Remote URL (`settingsUrl`)
3. Programmatic (`TealiumConfig` builders)

**SDKSettings** structure: `core` (CoreSettings), `modules`, `loadRules`, `transformations`, `barriers`, `consent`.

**CoreSettings** defaults: `maxQueueSize` 100, `queueExpiration` 1 day, `refreshInterval` 15 min, `sessionTimeout` 5 min.

### Thread Safety
All SDK operations run on `TealiumQueue.worker` (utility QoS DispatchQueue). `TealiumQueue.ensureOnQueue()` dispatches sync if already on queue, async otherwise. Public API access is thread-safe via `AsyncProxy<TealiumImpl>` which wraps operations on the worker queue. Use `[weak self]` in observable subscriptions.

### Persistence
SQLite via SQLite.swift (0.15.4+). Repositories: `QueueRepository`, `KeyValueRepository`, `ModulesRepository`. `DataStore` protocol with transactional `DataStoreEditor` (`put/remove/clear/commit`). Data expiration: `.forever`, `.session`, `.untilRestart`, `.after(Date)`, `.afterCustom(timeFrame)`.

### Reactive System (PubSub)
- `Observable<T>` - Base with `subscribe()`, `subscribeOnce()`, operators (map, filter, combineLatest)
- `Subject` - Property wrapper publishing an Observable
- `StateSubject` - Always has current value, emits on change via `publishIfChanged()`
- `ReplaySubject` - Caches and replays elements to new subscribers (default cache size 1)
- `Disposable` / `CompositeDisposable` / `AutomaticDisposer` - Cleanup on dispose/deinit

### Command API
`tealium-prism/core/API/Command/` — infrastructure for command-based dispatchers:
- `Command` — protocol: `name: String` + `execute(payload:completion:) -> Disposable`
- `SyncCommand` — convenience wrapper for synchronous commands
- `CommandName` — protocol for enum-backed command names (provides default `name` from `rawValue`)
- `CommandRegistry` — O(1) name-based routing (normalizes to lowercase, trimmed)
- `CommandDispatcher` — base class for dispatchers that route via a `CommandRegistry`; subclasses pass `commands: [Command]` to `super.init` and get `dispatch()` for free
- `CommandMappingsBuilder` — builder for mapping `CommandName` values to `Command` instances

### Barriers
`BarrierCoordinator` computes per-dispatcher open/closed state. Debounce 0.2s, flush timeout 5s. Built-in: `BatchingBarrier`, `ConnectivityBarrier`. Custom barriers extend `ConfigurableBarrier`.

### Transformations
`TransformerCoordinator` runs in two phases: afterCollectors (before consent) and dispatcher-specific (before send). Each `TransformationSettings` has `id`, `transformerId`, `scope` (`TransformationScope`: `.afterCollectors`, `.allDispatchers`, `.dispatchers([String])`), `configuration`, optional `conditions` (Rule<Condition>), and `order: Int` (lower runs first; defaults to `Int.max`).

`TransformationSettingsBuilder.build()` returns `DataObject` — pass the builder directly to `TealiumConfig.setTransformation(_:)`, no need to call `build()` yourself.

### Load Rules
`Rule<Item>` is an indirect enum: `.and([Rule])`, `.or([Rule])`, `.not(Rule)`, `.just(Item)`. `Condition` has `variable` (ReferenceContainer), `operator` (isDefined, equals, contains, regex, etc.), and optional `filter`. Applied via `LoadRuleEngine` to filter which collectors run per dispatch.

### Consent
`ConsentDecision` with `.implicit`/`.explicit` type and `purposes: Set<String>`. CMP integration via `CMPAdapter` protocol registered on `TealiumConfig.enableConsentIntegration()`. Dispatches dropped if "tealium" purpose is blocked.

### Session Management
`Session` tracks `status` (started/resumed/ended), `sessionId`, `lastEventTimeMilliseconds`, `eventCount`. `SessionManager` updates on each `track()` call.

### Instance Lifecycle
`TealiumInstanceManager` strongly retains every created `Tealium`/`TealiumImpl` instance (keyed by `TealiumConfig.key`) — dropping all external references no longer deallocates it. Instances are released only via explicit `Tealium.shutdown()` or `TealiumInstanceManager.shutdown(_:)`, which tears down modules, the dispatch loop, and the session manager. Any call made on a shut-down instance fails with `TealiumError.instanceShutdown`.

## Key Files

| File | Purpose |
|------|---------|
| `tealium-prism/core/API/Tealium.swift` | Main public API, singleton factory |
| `tealium-prism/core/API/TealiumConfig.swift` | Configuration builder |
| `tealium-prism/core/API/Modules/Module.swift` | Module/Collector/Dispatcher protocols |
| `tealium-prism/core/API/Transform/Transformer.swift` | Transformer protocol |
| `tealium-prism/core/API/Modules/TealiumContext.swift` | Dependency injection for modules |
| `tealium-prism/core/API/Modules/ModulesManager.swift` | Module lifecycle management |
| `tealium-prism/core/API/Data/DataObject.swift` | Dictionary wrapper |
| `tealium-prism/core/API/Data/DataItem.swift` | JSON value wrapper |
| `tealium-prism/core/API/Tracking/Dispatch.swift` | Event representation |
| `tealium-prism/core/Internal/Dispatch/TrackerImpl.swift` | Collector orchestration |
| `tealium-prism/core/Internal/Dispatch/DispatchManager.swift` | Queue, consent, dispatch loop |
| `tealium-prism/core/Internal/Dispatch/QueueManager.swift` | Per-dispatcher SQLite queues |
| `tealium-prism/core/Internal/Barriers/BarrierCoordinator.swift` | Barrier state management |
| `tealium-prism/core/Internal/Settings/SDKSettings.swift` | Settings container |
| `tealium-prism/core/API/PubSub/` | Observable/Subject/Disposable system |
| `tealium-prism/core/API/Persistence/Stores/DataStore.swift` | Storage protocol |
| `tealium-prism/core/API/Misc/TealiumQueue.swift` | Thread-safe queue |
| `tealium-prism/core/Internal/Misc/AsyncProxy.swift` | Thread-safe proxy |
| `Example/Tests/` | All tests organized by module |
| `Example/Tests/TestHelpers/` | Mocks, custom assertions, utilities |

## Test Infrastructure

Tests live in `Example/Tests/` organized by module (Core/, EndToEnd/, Lifecycle/, MomentsAPI/, Extensions/, JavaScriptTransformer/). Test plans in `Example/Tests/TestPlans/`.

**Test helpers** (`Example/Tests/TestHelpers/`):
- **Custom assertions:** `XCTAssertNSNull`, `XCTAssertNotNSNull`, `XCTAssert+BoolOptional`, `XCTAssert+EqualDictionaries`, `XCTAssert+Errors`, `XCTAssert+NaN`, `XCTAssert+ObservedValue`, `XCTAssert+Result`
- **Mocks (~33):** `MockTracker`, `MockContext`, `MockConfig`, `MockNetworkHelper`, `MockDatabaseProvider`, `MockQueueManager`, `MockSessionManager`, `MockDispatchManager`, `MockCollector`, `MockTransformer`, `MockDispatcher`, `MockBarrier`, `MockConnectivity`, `MockConsentManager`, `FailingMockDataStore`, `StubModuleFactory`, and more
- **Helpers:** `DeinitTester` (retain cycles), `CreateDispatches`, `XCTestCase+WaitForDefaultTimeout` (0.1s default, 10s long)

## SwiftLint Rules

**Source** (`.swiftlint.yml`):
- Included: `./tealium-prism/`
- Excluded: `AnyCodable/`, `Data+Gzip.swift`
- Line length: warning 200, error 500 (ignores comments)
- File length: warning 500
- Large tuple: 4
- Key opt-in rules: `force_unwrapping`, `sorted_imports`, `overridden_super_call`, `closure_spacing`, `first_where`, `array_init`
- Identifier exceptions: `id`, `or`
- Cyclomatic complexity ignores case statements
- Nesting ignores typealiases and associated types

**Tests** (`.swiftlint_test.yml`): Same rules but file length warning 700, type body length warning 500, `setUp/tearDown` excluded from `overridden_super_call`.

## CI/CD

GitHub Actions workflows (all triggered on pull requests):

**`.github/workflows/build-and-test.yml`**:
- **build_example**: Builds Example_iOS (CocoaPods)
- **build_SPM**: Builds SPM schemes for all platforms
- **test_{iOS,tvOS,macOS,watchOS}**: Runs all test schemes per platform (OS 18.5)

**`.github/workflows/lint.yml`**: SwiftLint source + tests (runs on `ubuntu-latest`), version validation.

**`.github/workflows/docs.yml`**: Documentation generation.

**`.github/workflows/deploy.yml`**: Deployment.

Setup uses a local composite action (`.github/workflows/setup-machine`).
