Barriers provide a powerful mechanism to control when dispatches are sent to dispatchers in the Tealium SDK. They act as gates that can block or allow the flow of events based on various conditions such as network connectivity, batch size requirements, or custom business logic.

## Overview

The barrier system consists of several key components:

- **`Barrier`**: The core protocol that defines how barriers control dispatch flow
- **`ConfigurableBarrier`**: Barriers that can be configured at runtime with settings
- **`BarrierScope`**: Defines which dispatchers a barrier applies to
- **`BarrierState`**: Represents whether a barrier is open (allowing dispatches) or closed (blocking dispatches)
- **`BarrierRegistry`**: Interface for registering custom barriers at runtime

Barriers are evaluated before each dispatch is sent to determine if the dispatch should proceed or be queued until conditions are met.

## Basic Concepts

### Barrier States

A barrier can be in one of two states:

```swift
public enum BarrierState {
    case closed  // Blocks dispatches from proceeding
    case open    // Allows dispatches to proceed
}
```

### Barrier Scopes

Barriers can be applied to different scopes within the dispatch pipeline:

```swift
public enum BarrierScope {
    case all                    // Apply to all dispatchers
    case dispatcher(id: String) // Apply only to specific dispatcher
}
```

### Flushable Barriers

Barriers can be marked as "flushable", meaning they can be bypassed during flush operations (`Tealium.flushEventQueue()`). This is useful for ensuring critical events are sent even if certain barriers are closed:

```swift
// A barrier that can be bypassed during flush
var isFlushable: Observable<Bool> { 
    Observables.just(true) 
    // or dynamic logic to determine flushability
}

// A barrier that cannot be bypassed during flush
var isFlushable: Observable<Bool> { 
    Observables.just(false) 
}
```

**Note**: If any barriers that are not flushable are closed, then the dispatch won't proceed regardless of the flushable barriers' states.

## Built-in Barriers

### Connectivity Barrier

The connectivity barrier blocks dispatches when network connectivity is unavailable or doesn't meet specified requirements.

```swift
// Add connectivity barrier that applies to collect dispatcher only (this is default behavior)
config.addBarrier(
    Barriers.connectivity(defaultScopes: [.dispatcher(id: Modules.Types.collect)])
)

// Add connectivity barrier that applies to all dispatchers
config.addBarrier(
    Barriers.connectivity(defaultScopes: [.all])
)
```

**Configuration Options:**
- `wifi_only`: When `true`, only allows dispatches over WiFi or Ethernet connections

**Behavior:**
- Blocks dispatches when no network connection is available
- Optionally blocks cellular connections when `wifi_only` is enabled
- Is flushable when any network connection is available
- Automatically opens when connectivity is restored

### Batching Barrier

The batching barrier blocks dispatches until a specified number of events have been queued for a dispatcher.

```swift
// Add batching barrier that applies to all dispatchers
config.addBarrier(
    Barriers.batching(defaultScopes: [.all])
)

// Add batching barrier that applies to specific dispatchers
config.addBarrier(
    Barriers.batching(defaultScopes: [.dispatcher(id: "analytics_dispatcher")])
)
```

**Configuration Options:**
- `batch_size`: Number of queued events required before opening the barrier

**Behavior:**
- Blocks dispatches until queue size reaches the configured batch size
- Uses `Dispatcher.dispatchLimit` as batch size, if `batch_size` value is greater than that
- Uses batch size of 1 if configured value is negative or zero
- Always flushable during flush operations

## Creating Custom Barriers

### Simple Barrier Implementation

This example shows a simple time-based barrier that periodically opens for a brief window to allow dispatches through. The barrier opens every specified interval and then closes again after 1 second.

**Important**: Barriers are used from the Tealium worker queue internally by the SDK. Always use `TealiumQueue.worker` when creating timers or performing operations that change barrier state, as using other queues might lead to crashes.

**Note**: This non-configurable barrier can only be added by a custom module created by the user using the `BarrierRegistry.registerScopedBarrier(_:scopes:)` method (see the **Runtime Barrier Management** section below). If you need to add barriers through the TealiumConfig, you should create a configurable barrier with its factory instead (see the **Configurable Barrier Implementation** section below).

```swift
class CustomTimerBarrier: Barrier {
    private var timer: RepeatingTimer?
    private var closeTimer: RepeatingTimer?
    @StateSubject(.closed)
    private var state: ObservableState<BarrierState>
    
    init(interval: TimeInterval) {
        timer = RepeatingTimer(timeInterval: interval, queue: TealiumQueue.worker) { [weak self] in
            self?._state.value = .open
            // Schedule closing the barrier after 1 second
            self?.closeTimer = RepeatingTimer(timeInterval: 1.0, repeating: .never, queue: TealiumQueue.worker) { [weak self] in
                self?._state.value = .closed
            }
            self?.closeTimer?.resume()
        }
        timer?.resume()
    }
    
    deinit {
        timer?.suspend()
        closeTimer?.suspend()
    }
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        state
    }
    
    // This barrier can be bypassed during flush operations
    var isFlushable: Observable<Bool> {
        Observables.just(true)
    }
}
```

### Configurable Barrier Implementation

```swift
class CustomBusinessLogicBarrier: ConfigurableBarrier {
    static var id: String = "CustomBusinessLogicBarrier"
    
    @StateSubject(.open)
    private var state: ObservableState<BarrierState>
    
    private var settings: BusinessLogicSettings
    
    init(configuration: DataObject) {
        self.settings = BusinessLogicSettings(dataObject: configuration)
        updateBarrierState()
    }
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        state
    }
    
    func updateConfiguration(_ configuration: DataObject) {
        settings = BusinessLogicSettings(dataObject: configuration)
        updateBarrierState()
    }
    
    private func updateBarrierState() {
        // Custom business logic to determine barrier state
        let shouldBlock = settings.maintenanceMode || 
                         !settings.allowedUserTypes.contains(getCurrentUserType())
        _state.value = shouldBlock ? .closed : .open
    }
    
    // Not flushable - business logic barriers should not be bypassed
    var isFlushable: Observable<Bool> {
        Observables.just(false)
    }
}

struct BusinessLogicSettings {
    let maintenanceMode: Bool
    let allowedUserTypes: [String]
    
    init(dataObject: DataObject) {
        maintenanceMode = dataObject.get(key: "maintenance_mode") ?? false
        allowedUserTypes = dataObject.getArray(key: "allowed_user_types", of: String.self)?
            .compactMap { $0 } ?? []
    }
}
```

### Barrier Factory Implementation

```swift
extension CustomBusinessLogicBarrier {
    class Factory: BarrierFactory {
        private let _defaultScopes: [BarrierScope]
        
        init(defaultScopes: [BarrierScope]) {
            self._defaultScopes = defaultScopes
        }
        
        func create(context: TealiumContext, configuration: DataObject) -> CustomBusinessLogicBarrier {
            CustomBusinessLogicBarrier(configuration: configuration)
        }
        
        func defaultScopes() -> [BarrierScope] {
            _defaultScopes
        }
    }
}
```

## Configuration

### Programmatic Configuration

```swift
// Register barrier factory during SDK initialization
// Only scopes can be set programmatically; other settings are handled via remote/local configuration
config.addBarrier(
    CustomBusinessLogicBarrier.Factory(defaultScopes: [.all])
)
```

### JSON Configuration

Barrier configuration is handled through remote settings or local JSON files.
The barrier will receive its configuration when created by the factory.

```json
{
  "barriers": {
    "ConnectivityBarrier": {
      "barrier_id": "ConnectivityBarrier",
      "scopes": ["all"],
      "configuration": {
        "wifi_only": true
      }
    },
    "BatchingBarrier": {
      "barrier_id": "BatchingBarrier", 
      "scopes": ["analytics_dispatcher", "collect_dispatcher"],
      "configuration": {
        "batch_size": 10
      }
    }
  }
}
```
The barriers will automatically receive `updateConfiguration()` calls when settings change.

## Runtime Barrier Management

### Registering Barriers at Runtime

If, for some reason, your Module implementation needs to register barriers at runtime, you can do so via the `BarrierRegistry`:

```swift
// Get the barrier registry from `TealiumContext`
let barrierRegistry = context.barrierRegistry

// Create and register a custom barrier
let customBarrier = CustomTimerBarrier(interval: 30.0)
barrierRegistry.registerScopedBarrier(
    customBarrier, 
    scopes: [.dispatcher(id: "my_dispatcher")]
)

// Unregister when no longer needed
barrierRegistry.unregisterScopedBarrier(customBarrier)
```

## Advanced Barrier Patterns

### Conditional Barriers

Create barriers that change behavior based on application status:

```swift
class ConditionalBarrier: ConfigurableBarrier {
    static var id: String = "ConditionalBarrier"
    
    @StateSubject(.open)
    private var state: ObservableState<BarrierState>
    
    private let onApplicationStatus: Observable<ApplicationStatus>
    private var subscription: Disposable?
    
    init(onApplicationStatus: Observable<ApplicationStatus>, configuration: DataObject) {
        self.onApplicationStatus = onApplicationStatus
        
        // Update barrier state based on application status
        subscription = onApplicationStatus.subscribe { [weak self] appStatus in
            let shouldBlock = appStatus.type == .backgrounded
            self?._state.value = shouldBlock ? .closed : .open
        }
    }
    
    deinit {
        subscription?.dispose()
    }
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        state
    }
    
    func updateConfiguration(_ configuration: DataObject) {
        // Handle configuration updates
        let blockInBackground = configuration.get(key: "block_in_background") ?? true
        // Update logic based on configuration
    }
}
```

### Dispatcher-Specific Barriers

Create barriers that behave differently for different dispatchers:

```swift
class DispatcherSpecificBarrier: Barrier {
    private let highPriorityDispatchers: Set<String>
    @StateSubject(.closed)
    private var generalState: ObservableState<BarrierState>
    
    init(highPriorityDispatchers: [String]) {
        self.highPriorityDispatchers = Set(highPriorityDispatchers)
    }
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        if highPriorityDispatchers.contains(dispatcherId) {
            // High priority dispatchers are never blocked
            return Observables.just(.open)
        } else {
            // Other dispatchers follow general state
            return generalState
        }
    }
    
    func setGeneralState(_ state: BarrierState) {
        _generalState.value = state
    }
}
```

### Time-Based Barriers

Create barriers that open and close based on time schedules:

```swift
class ScheduledBarrier: ConfigurableBarrier {
    static var id: String = "ScheduledBarrier"
    
    @StateSubject(.open)
    private var state: ObservableState<BarrierState>
    
    private var allowedHours: ClosedRange<Int> = 9...17
    private var timer: Timer?
    
    init(configuration: DataObject) {
        updateConfiguration(configuration)
        startTimer()
    }
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        state
    }
    
    func updateConfiguration(_ configuration: DataObject) {
        let startHour = configuration.get(key: "start_hour") ?? 9
        let endHour = configuration.get(key: "end_hour") ?? 17
        allowedHours = startHour...endHour
        updateStateForCurrentTime()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateStateForCurrentTime()
        }
    }
    
    private func updateStateForCurrentTime() {
        let currentHour = Calendar.current.component(.hour, from: Date())
        _state.value = allowedHours.contains(currentHour) ? .open : .closed
    }
}
```

## Flush Operations

### Understanding Flush Behavior

Flush operations allow you to bypass flushable barriers to ensure important events are sent:

```swift
// Trigger a flush operation
tealium.flushEventQueue()

// Flush is automatically triggered when:
// - Application status changes (backgrounded, foregrounded, initialized)
// - The system detects queued events that need to be sent
```

### Controlling Flush Behavior

```swift
class SelectivelyFlushableBarrier: Barrier {
    @StateSubject(true)
    private var canFlush: ObservableState<Bool>
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        // Barrier logic
        return Observables.just(.closed)
    }
    
    var isFlushable: Observable<Bool> {
        canFlush
    }
    
    func setFlushable(_ flushable: Bool) {
        _canFlush.value = flushable
    }
}
```

## Error Handling and Best Practices

### Error Handling

```swift
class RobustBarrier: ConfigurableBarrier {
    static var id: String = "RobustBarrier"
    
    @StateSubject(.open)
    private var state: ObservableState<BarrierState>
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        do {
            let calculatedState = try calculateBarrierState(for: dispatcherId)
            _state.value = calculatedState
        } catch {
            // Log error and default to open to avoid blocking dispatches
            print("Barrier error: \(error)")
            _state.value = .open
        }
        return state
    }
    
    private func calculateBarrierState(for dispatcherId: String) throws -> BarrierState {
        // Barrier logic that might throw
        return .open
    }
    
    func updateConfiguration(_ configuration: DataObject) {
        // Safely handle configuration updates
        do {
            let newState = try processConfiguration(configuration)
            _state.value = newState
        } catch {
            print("Configuration error: \(error)")
            // Keep current state on configuration errors
        }
    }
    
    private func processConfiguration(_ configuration: DataObject) throws -> BarrierState {
        // Configuration processing that might throw
        return .open
    }
}
```

### Best Practices

#### 1. Use Appropriate Scopes

```swift
// Good: Connectivity barrier only for network-dependent dispatchers
config.addBarrier(Barriers.connectivity(defaultScopes: [.dispatcher(id: "collect")]))

// Avoid: Applying connectivity barrier to local-only dispatchers unnecessarily
config.addBarrier(Barriers.connectivity(defaultScopes: [.all])) // if you have local-only dispatchers
```

#### 2. Handle Configuration Gracefully

```swift
func updateConfiguration(_ configuration: DataObject) {
    // Provide sensible defaults
    let batchSize = max(configuration.get(key: "batch_size") ?? 1, 1)
    let timeout = configuration.get(key: "timeout") ?? 30.0
    
    // Validate configuration
    guard timeout > 0 else {
        print("Invalid timeout configuration, using default")
        return
    }
    
    // Apply configuration
    applySettings(batchSize: batchSize, timeout: timeout)
}
```

#### 3. Implement Proper Resource Management

```swift
class ResourceManagedBarrier: ConfigurableBarrier {
    private var timer: Timer?
    private var subscription: Disposable?
    
    deinit {
        timer?.invalidate()
        subscription?.dispose()
    }
    
    // Implementation...
}
```

#### 4. Use TealiumQueue for State Changes

Always use `TealiumQueue.worker` when changing barrier state or performing operations that affect barrier behavior. Barriers are used from the Tealium worker queue internally by the SDK, and using other queues can lead to crashes:

```swift
// Good: Using TealiumQueue.worker
class SafeBarrier: Barrier {
    @StateSubject(.open)
    private var state: ObservableState<BarrierState>
    
    func updateState(_ newState: BarrierState) {
        TealiumQueue.worker.ensureOnQueue { [weak self] in
            self?._state.value = newState
        }
    }
}

// Avoid: Using other queues for state changes
class UnsafeBarrier: Barrier {
    func updateState(_ newState: BarrierState) {
        DispatchQueue.main.async { // This could cause crashes
            self._state.value = newState
        }
    }
}
```

#### 5. Use Descriptive Barrier IDs

```swift
// Good
static var id: String = "UserPermissionBarrier"

// Avoid
static var id: String = "Barrier1"
```

#### 6. Consider Performance Impact

```swift
// Efficient: Cache expensive calculations
class EfficientBarrier: Barrier {
    private var cachedState: BarrierState = .open
    private var lastCalculation: Date = .distantPast
    private let cacheTimeout: TimeInterval = 60
    
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        if Date().timeIntervalSince(lastCalculation) > cacheTimeout {
            cachedState = calculateExpensiveState()
            lastCalculation = Date()
        }
        return Observables.just(cachedState)
    }
}
```

## Integration with Other SDK Features

### Barriers and LoadRules

Barriers and LoadRules work together to provide comprehensive dispatch control:

```swift
// LoadRules determine IF a module should process a dispatch
config.setLoadRule(
    Rule.just(Condition.equals(ignoreCase: false, variable: "user_type", target: "premium")),
    forId: "premium_analytics"
)

// Barriers determine WHEN dispatches should be sent
config.addBarrier(
    Barriers.connectivity(defaultScopes: [.all])
)
```

### Barriers and Transformations

Barriers control dispatch timing while transformations modify dispatch content. The order of execution depends on the transformation scope:

- **`.afterCollectors` scope**: Transformations happen **before** barriers are checked
- **`.allDispatchers` and `.dispatcher(id)` scopes**: Transformations happen **after** a successful barrier check

```swift
// This transformation runs BEFORE barrier checks
let preBarrierTransformation = TransformationSettings(
    id: "user_enrichment",
    transformerId: "enrichment_transformer",
    scopes: [.afterCollectors]  // Runs before barriers
)

// This transformation runs AFTER barrier checks pass
let postBarrierTransformation = TransformationSettings(
    id: "data_formatting",
    transformerId: "format_transformer", 
    scopes: [.dispatcher(id: "AnalyticsDispatcher")]  // Runs after barriers
)
```

This execution order ensures that:
1. Data collection transformations (`.afterCollectors`) always run regardless of barrier state
2. Dispatch-specific transformations only run when barriers allow the dispatch to proceed
3. Resources aren't wasted on transformations for dispatches that will be blocked

## Monitoring and Debugging

### Barrier State Monitoring

Barrier state monitoring is handled internally by the SDK. You can observe the effects of barriers through:

- Event delivery timing
- Queue behavior during network connectivity changes
- Batch dispatch patterns

### Queue Monitoring

Queue monitoring is handled internally by the SDK. The batching barrier automatically responds to queue size changes, and you can observe its effects through the timing of event dispatches.

## Conclusion

Barriers provide essential control over when your analytics data is sent, ensuring optimal performance, respecting user preferences, and maintaining data quality. By understanding and properly implementing barriers, you can create a robust analytics implementation that adapts to various conditions and requirements.
