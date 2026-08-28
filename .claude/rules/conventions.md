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
