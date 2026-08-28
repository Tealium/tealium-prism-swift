---
paths:
  - "Example/Tests/**"
---

# Test Infrastructure

Tests live in `Example/Tests/`, organized by module: `Core/`, `EndToEnd/`, `Lifecycle/`, `MomentsAPI/`, `Extensions/`, `JavaScriptTransformer/`. Test plans are in `Example/Tests/TestPlans/`.

**Before writing tests, check `Example/Tests/TestHelpers/`** — it already holds the shared assertions and mocks. Reuse what's there instead of writing new helpers or inline workarounds. It contains:
- **Custom assertions** — `XCTAssert+*.swift` files, e.g. `XCTAssert+NSNull` (`XCTAssertNSNull`/`XCTAssertNotNSNull`), `XCTAssert+EqualDictionaries`, `XCTAssert+Errors`, `XCTAssert+ObservedValue`, `XCTAssert+Result`, `XCTAssert+BoolOptional`, `XCTAssert+NaN`.
- **Mocks** — `TestHelpers/Mocks/` (~30 files): `MockTracker`, `MockContext`, `MockConfig`, `MockNetworkHelper`, `MockNetworkClient`, `MockConnectivityManager`, `MockDatabaseProvider`, `MockQueueManager`, `MockSessionManager`, `MockCollector`, `MockTransformer`, `MockDispatcher`, `MockBarrier`, `MockConsentManager`, `FailingMockDataStore`, `StubModuleFactory`, and more. Browse the folder for the current list rather than assuming a name.
- **Other helpers** — `XCTestCase+WaitForDefaultTimeout` (0.1s default timeout, 10s long), `DeinitTester` / `RetainCycleHelper` (retain-cycle checks), `CreateDispatches`.

Test schemes are per-module and per-platform (`CoreTests_iOS`, etc.) — see the run commands in the root `CLAUDE.md`. SwiftLint applies to test code too, under `.swiftlint_test.yml` (see the SwiftLint section in the root `CLAUDE.md`).

## Testable Init Pattern for Modules

When a module (Transformer, Collector, Dispatcher, etc.) needs to be tested, add a direct initializer that accepts individual dependencies and make the `required init?(context:moduleConfiguration:)` a `convenience` that delegates to it. Tests then use the direct init to inject mocks without needing `MockContext`.

```swift
// Production code
class MyTransformer: Transformer, BasicModule {
    let tracker: Tracker
    let dataLayer: any DataStore

    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(tracker: context.tracker, dataLayer: context.dataLayer)
    }

    init(tracker: Tracker, dataLayer: any DataStore) {
        self.tracker = tracker
        self.dataLayer = dataLayer
    }
}

// Test code — no MockContext needed
override func setUpWithError() throws {
    dataLayer = try storeProvider.getModuleStore(name: "testModule")
    transformer = MyTransformer(tracker: MockTracker(), dataLayer: dataLayer)
}
```

Used in `PersistDataValueTransformer`, `JavaScriptTransformer`, and others.

## DataObject Extraction Patterns in Tests

**Arrays** — use `getArray(key:)` without `of:`, letting Swift infer the element type from the compared literal. The literal `["foo", "bar"]` is inferred as `[String?]`:
```swift
XCTAssertEqual(result?.payload.getArray(key: "tags"), ["foo", "bar"])
```

**Nested dictionaries** — use `getDataDictionary(key:)` → `[String: DataItem]?`, then `.get(key:)` with the type inferred from the compared value:
```swift
let nested = result?.payload.getDataDictionary(key: "nested")
XCTAssertEqual(nested?.get(key: "inner_key"), "upper_value")
```

**Scalar values** — never pass `as: Type.self` to `.get(key:)`; Swift infers the type from the compared literal:
```swift
// ✅
XCTAssertEqual(dataObject.get(key: Keys.scope), "aftercollectors")
// ❌ redundant
XCTAssertEqual(dataObject.get(key: Keys.scope, as: String.self), "aftercollectors")
```

**Key absence** — assert with `keys.contains(key)` rather than a typed getter. `get(key:as:)` returns `nil` for both an absent key and an `NSNull` value, so it can't distinguish the two.

See [conventions.md](conventions.md) for the corresponding DataObject *construction* patterns used in production and test fixtures.
