# Built-in Functions Reference

Reference documentation for all built-in Cypher functions in CongraphDB.

## Overview

CongraphDB supports a comprehensive set of built-in functions organized by category:

- **String Functions** - Text manipulation and formatting
- **Aggregation Functions** - Data summarization and grouping
- **List Functions** - List and collection operations
- **Math Functions** - Mathematical calculations
- **Path Functions** - Graph path operations
- **Temporal Functions** - Date and time handling

## Function Registry

Functions are registered in `src/query/evaluator/registry.rs` and implemented in `src/query/functions/`.

### Function Trait

All functions implement the `Function` trait:

```rust
pub trait Function: Send + Sync {
    fn name(&self) -> &str;
    fn return_type(&self, arg_types: &[LogicalType]) -> Option<LogicalType>;
    fn eval(&self, args: Vec<Value>) -> Result<Value>;
}
```

## String Functions

Located in `src/query/functions/string.rs`.

### toString(value)

Converts a value to its string representation.

```cypher
RETURN toString(123)      // "123"
RETURN toString(true)     // "true"
RETURN toString([1,2,3])  // "[1,2,3]"
```

**Arguments**: `value` - Any value

**Returns**: `STRING`

### toLower(string)

Converts a string to lowercase.

```cypher
RETURN toLower('Hello World')  // "hello world"
```

**Arguments**: `string` - STRING

**Returns**: `STRING`

### toUpper(string)

Converts a string to uppercase.

```cypher
RETURN toUpper('Hello World')  // "HELLO WORLD"
```

**Arguments**: `string` - STRING

**Returns**: `STRING`

### substring(string, start, length)

Extracts a substring from a string.

```cypher
RETURN substring('Hello World', 0, 5)  // "Hello"
RETURN substring('Hello World', 6, 5)  // "World"
```

**Arguments**:
- `string` - STRING
- `start` - INTEGER (0-indexed)
- `length` - INTEGER

**Returns**: `STRING`

### trim(string)

Removes leading and trailing whitespace.

```cypher
RETURN trim('  Hello World  ')  // "Hello World"
```

**Arguments**: `string` - STRING

**Returns**: `STRING`

### replace(string, search, replace)

Replaces occurrences of a substring.

```cypher
RETURN replace('Hello World', 'World', 'There')  // "Hello There"
```

**Arguments**:
- `string` - STRING
- `search` - STRING
- `replace` - STRING

**Returns**: `STRING`

### split(string, delimiter)

Splits a string into a list of substrings.

```cypher
RETURN split('a,b,c', ',')  // ["a", "b", "c"]
```

**Arguments**:
- `string` - STRING
- `delimiter` - STRING

**Returns**: `LIST<STRING>`

## Aggregation Functions

Located in `src/query/functions/aggregation.rs`.

### COUNT(* or expr)

Counts the number of rows or non-null values.

```cypher
MATCH (u:User)
RETURN COUNT(*) AS total_users

MATCH (u:User)
WHERE u.age > 25
RETURN COUNT(u.name) AS named_users
```

**Arguments**: `*` or any expression

**Returns**: `INTEGER`

### SUM(expr)

Returns the sum of numeric values.

```cypher
MATCH (u:User)
RETURN SUM(u.order_total) AS total_sales
```

**Arguments**: `expr` - Numeric expression

**Returns**: `FLOAT` or `INTEGER`

### AVG(expr)

Returns the average of numeric values.

```cypher
MATCH (u:User)
RETURN AVG(u.age) AS average_age
```

**Arguments**: `expr` - Numeric expression

**Returns**: `FLOAT`

### MIN(expr)

Returns the minimum value.

```cypher
MATCH (u:User)
RETURN MIN(u.age) AS youngest_age
```

**Arguments**: `expr` - Any comparable expression

**Returns**: Same type as input

### MAX(expr)

Returns the maximum value.

```cypher
MATCH (u:User)
RETURN MAX(u.age) AS oldest_age
```

**Arguments**: `expr` - Any comparable expression

**Returns**: Same type as input

### COLLECT(expr)

Collects values into a list.

```cypher
MATCH (u:User)
RETURN COLLECT(u.name) AS all_names
```

**Arguments**: `expr` - Any expression

**Returns**: `LIST<T>` where T is the expression type

## List Functions

Located in `src/query/functions/list_fn.rs`.

### SIZE(list)

Returns the number of elements in a list.

```cypher
RETURN size([1, 2, 3, 4])  // 4
MATCH (u:User)
WHERE size(u.tags) > 0
RETURN u.name
```

**Arguments**: `list` - LIST

**Returns**: `INTEGER`

### KEYS(node)

Returns property names of a node.

```cypher
MATCH (u:User {name: 'Alice'})
RETURN keys(u)  // ["name", "age", "email"]
```

**Arguments**: `node` - NODE

**Returns**: `LIST<STRING>`

### LABELS(node)

Returns labels of a node.

```cypher
MATCH (n)
RETURN labels(n)  // ["User", "Admin"]
```

**Arguments**: `node` - NODE

**Returns**: `LIST<STRING>`

### RANGE(start, end, step)

Generates a list of values in a range.

```cypher
RETURN range(0, 10)        // [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
RETURN range(0, 10, 2)      // [0, 2, 4, 6, 8, 10]
```

**Arguments**:
- `start` - INTEGER
- `end` - INTEGER
- `step` - INTEGER (optional, default 1)

**Returns**: `LIST<INTEGER>`

## Math Functions

Located in `src/query/functions/math.rs`.

### ABS(value)

Returns the absolute value.

```cypher
RETURN abs(-5)   // 5
RETURN abs(3.14) // 3.14
```

**Arguments**: `value` - Numeric

**Returns**: Same type as input

### CEIL(value)

Rounds up to the nearest integer.

```cypher
RETURN ceil(3.14)  // 4
RETURN ceil(-2.7)  // -2
```

**Arguments**: `value` - Numeric

**Returns**: `FLOAT`

### FLOOR(value)

Rounds down to the nearest integer.

```cypher
RETURN floor(3.14)  // 3
RETURN floor(-2.7)  // -3
```

**Arguments**: `value` - Numeric

**Returns**: `FLOAT`

### ROUND(value)

Rounds to the nearest integer.

```cypher
RETURN round(3.14)  // 3
RETURN round(3.5)   // 4
```

**Arguments**: `value` - Numeric

**Returns**: `FLOAT`

### SQRT(value)

Returns the square root.

```cypher
RETURN sqrt(16)  // 4
RETURN sqrt(2)   // 1.414...
```

**Arguments**: `value` - Numeric (non-negative)

**Returns**: `FLOAT`

### LOG(value)

Returns the natural logarithm.

```cypher
RETURN log(e)  // 1.0
```

**Arguments**: `value` - Numeric (positive)

**Returns**: `FLOAT`

### EXP(value)

Returns e raised to the power of the value.

```cypher
RETURN exp(1)  // 2.718...
```

**Arguments**: `value` - Numeric

**Returns**: `FLOAT`

### POW(base, exponent)

Raises a number to a power.

```cypher
RETURN pow(2, 8)  // 256
RETURN pow(10, 2) // 100
```

**Arguments**:
- `base` - Numeric
- `exponent` - Numeric

**Returns**: `FLOAT`

## Path Functions

Located in `src/query/functions/path.rs`.

### shortestPath(start, end, relationship_types, direction) (planned)

Finds the shortest path between two nodes.

```cypher
MATCH (a:User {name: 'Alice'}), (b:User {name: 'Bob'})
RETURN shortestPath((a)-[:KNOWS*]-(b))
```

### allShortestPaths(start, end, relationship_types, direction) (planned)

Finds all shortest paths between two nodes.

```cypher
MATCH (a:User {name: 'Alice'}), (b:User {name: 'Bob'})
RETURN allShortestPaths((a)-[:KNOWS*]-(b))
```

## Temporal Functions

Located in `src/query/functions/temporal.rs`.

### DATE(string) (planned)

Parses a date string.

```cypher
RETURN date('2024-01-15')
```

### DATETIME(string) (planned)

Parses a datetime string.

```cypher
RETURN datetime('2024-01-15T10:30:00')
```

### TIMESTAMP() (planned)

Returns the current Unix timestamp.

```cypher
RETURN timestamp()  // 1705300200
```

### DURATION(amount, unit) (planned)

Creates a duration.

```cypher
RETURN duration(5, 'days')
```

## Custom Functions

Custom functions can be registered through the Rust API:

```rust
registry.register(Arc::new(MyCustomFunction));
```

## See Also

- [Query Execution](query-execution.md) — How functions are executed
- [Binder](binder.md) — Function type checking
- [Operators](operators.md) — Physical operators
