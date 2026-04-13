# Tealium Prism SDK (Swift) — Code Review Standards

## Project Overview
Multi-platform Swift SDK (iOS 13+, tvOS 13+, watchOS 7+, macOS 10.15+) — modular data collection, transformation and delivery. SPM-based. Each module ships a Swift target + ObjC bridge (e.g. TealiumPrismCore + TealiumPrismCoreObjC).

## Architecture
- `core/API/` — Public protocols and types. `core/Internal/` — Implementation details.
- `lifecycle/`, `momentsapi/` — Additional modules with the same API/Internal split.
- Vendor dispatchers are separate SPM packages depending on TealiumPrismCore.
- **Critical**: `Internal/` types must not be `public` unless required for ObjC bridging.

## Review Style
- Describe the risk if the issue is not fixed — no priority labels.
- Always provide remediation steps and show an example of desirable code.
- Address code, not the author: "Logic does not result in desired behavior", not "you did this wrong".

## Known Footguns — Must Catch

**DataItem casting trap** — `getDataArray()` returns `[DataItem]?`, NOT `[String]?`. Correct: `dataItem.getArray(of: String.self)`. Flag any direct cast of `getDataArray()`.

**DispatchQueue.sync is banned** — use `TealiumQueue.ensureOnQueue(_:)` only. `DispatchQueue.sync` risks deadlocks. Flag any occurrence.

**Dispatcher completion contract** — `dispatch(_:completion:)` completion MUST fire exactly once per `Dispatch`. Double-call = crash. Missing call = queue stuck forever. Use `SelfDestructingResultCompletion`.

**Silent module init** — `BasicModule.init?` returning `nil` silently skips the module. Log the reason via `context.logger?.warn(category:_:)` before returning `nil`.

**updateConfiguration nil = disabled** — returning `nil` shuts the module down. Verify `shutdown()` cleans up and behavior is documented.

**Untracked subscriptions = leak** — every `subscribe()` must `.addTo(compositeDisposable)` or call `dispose()`. Check `[weak self]` in closures to prevent retain cycles.

**Normalization symmetry** — `CommandRegistry` trims whitespace and lowercases on init (`trimmingCharacters(in: .whitespaces).lowercased()`). Lookups must normalize the same way. Flag asymmetric init/lookup normalization.

## Existing Utilities — Flag Duplication
Before approving, check if an existing utility covers the use case:

| Custom... | Use existing: |
|---|---|
| JSON encode/decode | `Tealium.jsonEncoder/.jsonDecoder`, `DataObject.serialize()`, `String.deserializeCodable<T>()` |
| String-to-number | `DataItemFormatter.number(from:)` (locale-fixed, NaN/Infinity-aware) |
| Type coercion | `LenientConverters.double/.int/.bool/.string` |
| JSONPath | `JSONObjectPath.parse(_:)` + `DataItemExtractor.extractDataItem(path:)` |
| Deep-write nested dict | `DataObject.buildPath(_:andSet:)` |
| Timer / debounce | `RepeatingTimer`, `Debouncer` (`DebouncerProtocol` for tests) |
| One-shot completion | `SelfDestructingResultCompletion` / `SelfDestructingCompletion` |
| Value clamping | `Comparable.coerce(min:max:)` |
| Empty/whitespace check | `String.isBlank` |
| Template `{{ }}` | `TemplateProcessor` (supports `{{key \|\| fallback}}`) |
| Background task | `BackgroundTaskStarter` (returns `Observable<Bool>`) |
| Array dedup/partition | `.removingDuplicates(by:and:)`, `.partitioned(by:)`, `.diff(_:by:)` |
| Date formatting | `Date.Formatter.iso8601/.iso8601Local/.MMDDYYYY` |
| Weak ref in collection | `Weak<T>` struct |
| Retry backoff | `ExponentialBackoff` (conforms to `BackoffPolicy`) |
