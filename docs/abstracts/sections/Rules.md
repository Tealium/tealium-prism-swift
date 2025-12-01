# LoadRules system

LoadRules provide a powerful way to control when modules in the Tealium SDK execute their functionality. They allow you to define conditional logic that determines whether data collection, event dispatching, or other module operations should occur based on the current state of your application's data.

## Overview

The LoadRules system consists of two main components:

- **`Condition`**: Individual criteria that evaluate data against specific requirements
- **`Rule`**: Logical compositions of conditions using boolean operators (AND, OR, NOT)

LoadRules are evaluated against each dispatch's payload data to determine if a module should process that dispatch.

## Basic Concepts

### Conditions

A `Condition` represents a single criterion that checks if data in your application meets specific requirements. For example:

```swift
// Check if user type equals "premium"
let condition = Condition.equals(ignoreCase: false, 
                                variable: "user_type", 
                                target: "premium")

// Check if purchase amount is greater than 100
let condition = Condition.isGreaterThan(orEqual: false,
                                       variable: JSONPath["order"]["amount"], 
                                       number: "100")
```

### Rules

A `Rule` allows you to combine multiple conditions using logical operators:

```swift
// Simple rule with just one condition
let simpleRule = Rule.just(condition)

// AND rule - all rule applying results must be true
let andRule = Rule.and([rule_1, rule_2, rule_3])

// OR rule - at least one rule applying result must be true  
let orRule = Rule.or([rule_1, rule_2])

// NOT rule - negates the result
let notRule = Rule.not(anotherRule)
```

## Data Access

### Flat Keys

For data at the root level of your payload, use simple string keys:

```swift
// Accesses payload["user_id"]
let condition = Condition.equals(ignoreCase: false,
                                variable: "user_id",
                                target: "12345")
```

### Nested Data with JSONPath

For nested data structures, use `JSONPath` to navigate through objects and arrays:

```swift
// Accesses payload.user.profile.subscription.type
let path = JSONPath["user"]["profile"]["subscription"]["type"]
let condition = Condition.equals(ignoreCase: false,
                                variable: path,
                                target: "premium")

// Accesses payload.items[0].price
let arrayPath = JSONPath["items"][0]["price"]
let condition = Condition.isGreaterThan(orEqual: false,
                                       variable: arrayPath,
                                       number: "50.00")
```

## Condition Types

### Existence Checks

```swift
// Check if a variable exists
Condition.isDefined(variable: "user_id")
Condition.isNotDefined(variable: "guest_session")

// Check if a variable is empty
Condition.isEmpty(variable: "shopping_cart")
Condition.isNotEmpty(variable: "user_preferences")
```

### Equality Comparisons

```swift
// Exact equality
Condition.equals(ignoreCase: false, variable: "status", target: "active")
Condition.equals(ignoreCase: true, variable: "country", target: "USA")

// Inequality
Condition.doesNotEqual(ignoreCase: false, variable: "user_type", target: "guest")
```

### String Operations

```swift
// Contains substring
Condition.contains(ignoreCase: false, variable: "page_url", string: "/checkout")
Condition.doesNotContain(ignoreCase: true, variable: "user_agent", string: "bot")

// Starts/ends with
Condition.startsWith(ignoreCase: false, variable: "event_name", prefix: "purchase_")
Condition.endsWith(ignoreCase: false, variable: "page_path", suffix: ".html")
Condition.doesNotStartWith(ignoreCase: false, variable: "product_id", prefix: "test_")
Condition.doesNotEndWith(ignoreCase: false, variable: "email", suffix: "@company.com")
```

### Numeric Comparisons

```swift
// Greater than comparisons
Condition.isGreaterThan(orEqual: false, variable: "order_total", number: "100.00")
Condition.isGreaterThan(orEqual: true, variable: "user_age", number: "18")

// Less than comparisons  
Condition.isLessThan(orEqual: false, variable: "cart_items", number: "10")
Condition.isLessThan(orEqual: true, variable: "session_duration", number: "3600")
```

### Regular Expressions

```swift
// Pattern matching using NSRegularExpression format
Condition.regularExpression(variable: "email", regex: "^[A-Za-z0-9+_.-]+@(.+)$")
Condition.regularExpression(variable: "phone", regex: "^\\+?[1-9]\\d{1,14}$")
```

## Complex Rule Compositions

### Combining Multiple Conditions

```swift
// Premium users OR high-value purchases
let premiumOrHighValue = Rule.or([
    .just(Condition.equals(ignoreCase: false, variable: "user_type", target: "premium")),
    .just(Condition.isGreaterThan(orEqual: false, variable: "order_total", number: "500.00"))
])

// Active users with valid email AND not in test mode
let activeValidUsers = Rule.and([
    .just(Condition.equals(ignoreCase: false, variable: "user_status", target: "active")),
    .just(Condition.regularExpression(variable: "email", regex: "^[A-Za-z0-9+_.-]+@(.+)$")),
    .not(.just(Condition.equals(ignoreCase: false, variable: "test_mode", target: "true")))
])
```

### Nested Logic

```swift
// Complex business logic: (Premium users OR VIP users) AND (not in maintenance mode)
let complexRule = Rule.and([
    .or([
        .just(Condition.equals(ignoreCase: false, variable: "subscription", target: "premium")),
        .just(Condition.equals(ignoreCase: false, variable: "vip_status", target: "true"))
    ]),
    .not(.just(Condition.equals(ignoreCase: false, variable: "maintenance_mode", target: "true")))
])
```

## Configuration

### SDK Settings Structure

The LoadRules system uses a two-level configuration approach in SDK settings:

1. **Load Rules Definition**: Define reusable rules with conditions in the `load_rules` section
2. **Module Rules Assignment**: Reference these rules by ID in individual module configurations

#### SDK Settings JSON Structure

```json
{
  "load_rules": {
    "premium_users": {
      "id": "premium_users",
      "conditions": {
        "operator": "equals",
        "variable": {"key": "user_type"},
        "filter": {"value": "premium"}
      }
    },
    "high_value_orders": {
      "id": "high_value_orders", 
      "conditions": {
        "operator": "greater_than",
        "variable": {"key": "order_total"},
        "filter": {"value": "100.00"}
      }
    },
    "mobile_users": {
      "id": "mobile_users",
      "conditions": {
        "operator": "contains",
        "variable": {"key": "user_agent"},
        "filter": {"value": "Mobile"}
      }
    }
  },
  "modules": {
    "analytics_collector": {
      "enabled": true,
      "rules": {
        "operator": "or",
        "children": ["premium_users", "high_value_orders"]
      }
    },
    "mobile_dispatcher": {
      "enabled": true, 
      "rules": {
        "operator": "and",
        "children": ["mobile_users", "premium_users"]
      }
    }
  }
}
```

### Programmatic Configuration (SDK Settings)

```swift
// Define reusable conditions
let isPremiumUser = Condition.equals(ignoreCase: false, variable: "user_type", target: "premium")
let isHighValue = Condition.isGreaterThan(orEqual: false, variable: "order_total", number: "100.00")

// Create a rule
let premiumOrHighValueRule = Rule.or([
    .just(isPremiumUser),
    .just(isHighValue)
])

// Apply to configuration
config.setLoadRule(premiumOrHighValueRule, forId: "premium_tracking")
```

### Programmatic Configuration (Module)

When configuring modules, you reference load rules by their IDs rather than defining conditions directly:

```swift
// Configure a module to use specific load rules
let moduleSettings = CollectorSettingsBuilder()
    .setEnabled(true)
    .setRules(Rule.or(["premium_users", "high_value_orders"]))
    .build()

config.addModule(AnalyticsCollector.Factory(forcingSettings: moduleSettings))
```

#### Rule ID References

Module rules use `Rule<String>` where the strings are IDs that reference load rules defined in the SDK settings:

```swift
// Simple rule reference
.setRules(Rule.just("premium_users"))

// Complex rule composition with multiple IDs
.setRules(Rule.and([
    Rule.or(["premium_users", "vip_users"]),
    Rule.not(Rule.just("test_mode"))
]))
```


## Data Type Handling

### Automatic Type Conversion

The system automatically handles type conversions:

```swift
// Numeric comparisons work with strings that can be parsed as numbers
Condition.isGreaterThan(orEqual: false, variable: "price", number: "29.99")

// String operations convert other types to strings
Condition.contains(ignoreCase: false, variable: "product_ids", string: "12345")
```

### Array and Object Handling

```swift
// Arrays are converted to comma-separated strings for string operations
// {"tags": ["electronics", "mobile", "smartphone"]} becomes "electronics,mobile,smartphone"
Condition.contains(ignoreCase: false, variable: "tags", string: "mobile")

// Objects cannot be used with string operations (will throw an error)
// Use isDefined/isNotDefined for object existence checks
Condition.isDefined(variable: JSONPath["user"]["preferences"])
```

## Error Handling

### Common Error Scenarios

LoadRules can encounter several types of errors during evaluation:

1. **Missing Data**: When a required variable doesn't exist in the payload
2. **Type Mismatches**: When operations are attempted on incompatible data types
3. **Invalid Filters**: When required filter values are missing or invalid
4. **Rule Not Found**: When a referenced rule ID doesn't exist

### Error Behavior

When errors occur during rule evaluation:

- The condition/rule evaluation fails
- The module is prevented from executing (fail-safe behavior)
- Errors are logged for debugging purposes
- The dispatch continues to other modules

```swift
// This will throw ConditionEvaluationError if "missing_field" doesn't exist
let condition = Condition.equals(ignoreCase: false, variable: "missing_field", target: "value")

// Safe alternative - check existence first
let safeRule = Rule.and([
    .just(Condition.isDefined(variable: "field")),
    .just(Condition.equals(ignoreCase: false, variable: "field", target: "value"))
])
```

## Best Practices

### 1. Use Descriptive Rule IDs

```swift
// Good
config.setLoadRule(rule, forId: "premium_users_high_value_purchases")

// Avoid
config.setLoadRule(rule, forId: "rule1")
```

### 2. Check Data Existence

```swift
// Defensive programming - check if data exists before using it
let safeRule = Rule.and([
    .just(Condition.isDefined(variable: "user_type")),
    .just(Condition.equals(ignoreCase: false, variable: "user_type", target: "premium"))
])
```

### 3. Use Case-Insensitive Comparisons When Appropriate

```swift
// For user input or data that might vary in case
Condition.equals(ignoreCase: true, variable: "country_code", target: "US")
```

### 4. Optimize Rule Complexity

```swift
// Put most likely to fail conditions first in AND rules
Rule.and([
    .just(Condition.equals(ignoreCase: false, variable: "rare_condition", target: "true")),
    .just(Condition.isDefined(variable: "common_field"))  // This won't be checked if first fails
])

// Put most likely to succeed conditions first in OR rules  
Rule.or([
    .just(Condition.isDefined(variable: "common_field")),
    .just(Condition.equals(ignoreCase: false, variable: "rare_condition", target: "true"))
])
```

### 5. Handle Edge Cases

```swift
// Account for empty values
Rule.and([
    .just(Condition.isDefined(variable: "email")),
    .just(Condition.isNotEmpty(variable: "email")),
    .just(Condition.regularExpression(variable: "email", regex: "^[A-Za-z0-9+_.-]+@(.+)$"))
])
```

## Module Integration

LoadRules are automatically applied by the SDK when modules process dispatches. The integration works through a two-step process:

### Rule Resolution Process

1. **Load Rule Definition**: Rules with conditions are defined in the `load_rules` section of SDK settings
2. **Module Rule Assignment**: Modules reference these rules by ID in their configuration
3. **Runtime Resolution**: The LoadRuleEngine expands rule ID references into executable conditions
4. **Dispatch Evaluation**: Each dispatch is evaluated against the resolved rules for each module

### Dispatch Processing Flow

When a dispatch occurs:

1. The SDK evaluates the LoadRule for each module by resolving rule IDs to their conditions
2. If the rule passes, the module processes the dispatch
3. If the rule fails, the module skips processing
4. If rule evaluation throws an error (e.g., rule ID not found), the module skips processing, the error is logged, and the dispatch continues to other modules

### Example Integration

```swift
// SDK Settings define the load rules
let sdkSettings = [
    "load_rules": [
        "premium_users": [
            "id": "premium_users",
            "conditions": [
                "operator": "equals",
                "variable": ["key": "user_type"],
                "filter": ["value": "premium"]
            ]
        ]
    ],
    "modules": [
        "analytics_collector": [
            "enabled": true,
            "rules": [
                "operator": "just",
                "children": ["premium_users"]  // References the load rule ID
            ]
        ]
    ]
]
```

This ensures that modules only operate on data that meets your specified criteria, providing fine-grained control over when different parts of your analytics implementation are active.

## Special Rule IDs

### "all" Rule

The special rule ID "all" always evaluates to true and can be used when you want a module to process all dispatches:

```swift
// This module will process every dispatch
.setRules(Rule.just("all"))
```

### Rule ID Resolution

When modules reference rule IDs, the LoadRuleEngine resolves them as follows:

1. **"all"**: Always evaluates to true (allows all dispatches)
2. **Defined Rule ID**: Uses the corresponding load rule from SDK settings
3. **Missing Rule ID**: Throws an error and prevents module execution (fail-safe behavior)

```swift
// Example of rule ID resolution in module configuration
.setRules(Rule.and([
    Rule.just("all"),              // Always true
    Rule.just("premium_users"),    // References load_rules["premium_users"]
    Rule.not(Rule.just("test_mode")) // References load_rules["test_mode"]
]))
```

## Performance Considerations

- Rules are evaluated for each dispatch, so keep them as simple as possible
- Use early-exit patterns (AND/OR short-circuiting) to optimize performance
- Avoid overly complex nested rules that are difficult to debug

## Conclusion

LoadRules provide a powerful and flexible way to control your analytics implementation, ensuring that the right data is collected and sent at the right times based on your specific business requirements.
