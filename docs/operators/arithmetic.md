# Arithmetic Operators

Mathematical operators for numeric computations.

## Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `+` | Addition | `u.age + 1` |
| `-` | Subtraction | `u.balance - 10` |
| `*` | Multiplication | `u.hours * u.rate` |
| `/` | Division | `u.total / u.count` |
| `%` | Modulo (remainder) | `u.id % 10` |
| `^` | Exponentiation | `2 ^ 8` |
| `+` | Unary plus | `+5` |
| `-` | Unary minus | `-5` |

## Examples

### Basic Arithmetic

```cypher
-- Calculate age plus one
RETURN u.age + 1 AS next_age

-- Calculate total from price and tax
RETURN p.price + (p.price * p.tax_rate) AS total
```

### Division

```cypher
-- Average calculation (integer division)
RETURN total_amount / item_count AS average

-- For precise division, use FLOAT64
RETURN CAST(total_amount AS FLOAT64) / item_count
```

### Modulo

```cypher
-- Find users with even IDs
MATCH (u:User)
WHERE u.id % 2 = 0
RETURN u
```

### Exponentiation

```cypher
-- Square a value
RETURN u.value ^ 2 AS squared

-- Cube root
RETURN u.value ^ (1/3) AS cube_root
```

## Operator Precedence

Precedence (highest to lowest):
1. Unary `+`, unary `-`
2. `^`
3. `*`, `/`, `%`
4. `+`, `-`

Use parentheses for clarity:

```cypher
-- Ambiguous
u.value + u.rate * u.tax

-- Clear
u.value + (u.rate * u.tax)
```

## Type Promotion

Operations return appropriate types:

| Operation | Operand Types | Result Type |
|-----------|--------------|-------------|
| `+`, `-`, `*` | INT64, INT64 | INT64 |
| `+`, `-`, `*` | INT64, FLOAT64 | FLOAT64 |
| `+`, `-`, `*` | FLOAT64, FLOAT64 | FLOAT64 |
| `/` | any | FLOAT64 |
| `%` | INT64, INT64 | INT64 |
| `^` | any | FLOAT64 |

## Overflow

Arithmetic overflow wraps around:

```cypher
-- INT64 overflow (undefined behavior)
RETURN 9223372036854775807 + 1  // Wraps to negative
```

For large numbers, consider FLOAT64:

```cypher
-- Safer for large values
RETURN CAST(9223372036854775807 AS FLOAT64) + 1.0
```

## NULL Handling

Any arithmetic operation with NULL returns NULL:

```cypher
-- NULL + 5 = NULL
-- NULL * 2 = NULL
RETURN u.value + NULL  // Returns NULL
```

## Common Patterns

### Percentage Calculation

```cypher
RETURN (u.part / u.total) * 100 AS percentage
```

### Currency Conversion

```cypher
RETURN p.price * 1.09 AS price_in_euros
```

### Age Calculation

```cypher
RETURN TIMESTAMP '2024-01-01' - u.birth_date AS age_in_ms
```

## See Also

- [Math Functions](../api/cypher.md#mathematical) — ABS, CEIL, FLOOR, etc.
- [Comparison Operators](comparison.md) — Comparing numeric values
