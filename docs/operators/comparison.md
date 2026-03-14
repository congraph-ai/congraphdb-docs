# Comparison Operators

Operators for comparing values.

## Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `=` | Equal | `u.age = 25` |
| `<>` | Not equal | `u.name <> 'Alice'` |
| `!=` | Not equal (alias) | `u.name != 'Alice'` |
| `<` | Less than | `u.age < 30` |
| `>` | Greater than | `u.age > 18` |
| `<=` | Less than or equal | `u.age <= 65` |
| `>=` | Greater than or equal | `u.age >= 21` |

## Examples

### Equality

```cypher
-- Find user named Alice
MATCH (u:User {name: 'Alice'})
RETURN u

-- Using WHERE clause
MATCH (u:User)
WHERE u.name = 'Alice'
RETURN u
```

### Inequality

```cypher
-- Find users not named Alice
MATCH (u:User)
WHERE u.name <> 'Alice'
RETURN u
```

### Range Queries

```cypher
-- Find users between 25 and 35
MATCH (u:User)
WHERE u.age >= 25 AND u.age <= 35
RETURN u.name, u.age
```

### Null Handling

```cypher
-- Comparison with NULL returns NULL (not true/false)
MATCH (u:User)
WHERE u.email = NULL  -- This won't match any rows

-- Use IS NULL instead
MATCH (u:User)
WHERE u.email IS NULL
RETURN u
```

## Type Compatibility

Comparisons work between compatible types:

| Type A | Type B | Result |
|--------|--------|--------|
| INT64 | INT64 | Numeric comparison |
| INT64 | FLOAT64 | Numeric comparison |
| FLOAT64 | FLOAT64 | Numeric comparison |
| STRING | STRING | Lexicographic comparison |
| BOOL | BOOL | Boolean comparison |

Cross-type comparisons (e.g., STRING vs INT64) will return an error.

## See Also

- [Logical Operators](logical.md) — AND, OR, NOT
- [String Operators](string.md) — String-specific comparisons
