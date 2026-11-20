---
paths:
  - "tealium-prism/**/*.swift"
  - "Example/**/*.swift"
---

# Prism Code Conventions

Project-specific conventions for writing SDK (`tealium-prism/`) and example-app (`Example/`) Swift code. Test-only conventions live in [testing.md](testing.md).

## DataObject Construction & Compacting

Prefer literal dictionary syntax over the builder pattern:

**✅ Preferred:**
```swift
func toDataObject() -> DataObject {
    [
        OperationKeys.destination: destination,
        OperationKeys.parameters: [
            Keys.updatePolicy: updatePolicy.rawValue,
            Keys.duration: expiryPolicy,
            Keys.input: input
        ] as DataObject
    ]
}
```

Avoid the imperative `.set(converting:key:)` builder style for construction.

The domain types (`ReferenceContainer`, `ExpiryPolicy`, `ValueSource`, etc.) are compatible with `DataObject` and can be assigned directly.

**When any root value is optional**, use `DataObject(compacting:)` — the literal syntax requires non-optional `DataInputConvertible` values and won't compile with optionals:

```swift
// ✅ Compiles; nil entries are omitted
DataObject(compacting: [
    Keys.allVariables: allVariables,   // Bool? — omitted if nil
    Keys.input: input,                 // ValueSource? — omitted if nil
])

// ❌ Does not compile when values are optional
[Keys.allVariables: allVariables] as DataObject
```

## Disposables — use the public factory, not internal types

Before making an internal type `public` to fix a cross-target access error, check whether it's already reachable through a public factory. The `Disposables` enum in `tealium-prism/core/API/PubSub/Disposables.swift` provides factories for all disposable types:

| Internal type | Public factory |
|---|---|
| `DisposableContainer` | `Disposables.composite()` → `CompositeDisposable` |
| `AsyncDisposableContainer` | `Disposables.composite(queue:)` → `CompositeDisposable` |
| `AutomaticDisposer` | `Disposables.automatic()` → `CompositeDisposable` |
| `Subscription` | `Disposables.subscription(onDispose:)` → `Disposable` |

There is also `Disposables.composite(for tealium:)` and `Disposables.disposed()`. Use a factory and type the property against the protocol:
```swift
// ❌ Don't: uses internal type directly
let automaticDisposer = AutomaticDisposer()

// ✅ Do: use public factory + protocol type
let disposables: CompositeDisposable = Disposables.automatic()
```

## Public API Changes Checklist

When adding or changing a `public` or `open` type/member:
1. Add a doc comment to the newly public type/member.
2. Ask the user whether the file should be moved to the module's `API/` folder before proceeding.
3. Update related `.md` docs (in `docs/` and subfolders) — they are not auto-generated and go stale silently.
4. Check and update the example app (`TealiumHelper`) if the change affects it or can be presented by new feature in the app.

## Public Enums — `@nonexhaustive` by Default

Prism ships as source with library evolution off, so a customer can `switch` exhaustively over any public enum, and adding a case breaks their build. Mark every new public enum `@nonexhaustive` ([SE-0487](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0487-extensible-enums.md)) so customers must handle unknown cases with `@unknown default`. Leave an enum exhaustive only if its set of cases is closed by design (e.g. a two-state result that can never gain a third state). Case-less namespace enums (`Modules`, `Disposables`, …) are unaffected.

Wrap the attribute in a `hasAttribute` guard so the minimum compiler stays at Swift 6.0 — compilers older than 6.2.3 don't know the attribute and skip it:

```swift
/// Doc comment stays above the guard.
#if hasAttribute(nonexhaustive)
@nonexhaustive
#endif
public enum SomeError: ErrorEnum {
```

- Use plain `@nonexhaustive`, not `@nonexhaustive(warn)`: the `(warn)` variant stays a warning even for Swift 6 language mode clients.
- Code in the same package (all SDK targets) is exempt, so SDK-internal switches don't need `@unknown default`.
- Marking an existing exhaustive enum is itself a breaking change for customers; call it out in the release notes.
