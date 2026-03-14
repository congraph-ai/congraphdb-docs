# String Operators

Operators for working with string values.

## Comparison Operators

Strings can be compared using standard comparison operators:

```cypher
-- Equality
WHERE u.name = 'Alice'

-- Inequality
WHERE u.name <> 'Bob'

-- Less than (lexicographic)
WHERE u.name < 'Eve'

-- Greater than or equal
WHERE u.name >= 'Charlie'
```

## String Matching Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `STARTS WITH` | String starts with prefix | `u.name STARTS WITH 'A'` |
| `ENDS WITH` | String ends with suffix | `u.email ENDS WITH '.com'` |
| `CONTAINS` | String contains substring | `u.name CONTAINS 'ana'` |
| `=~` | Regular expression match | `u.email =~ '.*@example\\.com'` |

## Examples

### STARTS WITH

```cypher
-- Find users whose name starts with 'A'
MATCH (u:User)
WHERE u.name STARTS WITH 'A'
RETURN u.name

-- Case-sensitive
WHERE u.name STARTS WITH 'alice'  -- Won't match 'Alice'
```

### ENDS WITH

```cypher
-- Find users with @example.com email
MATCH (u:User)
WHERE u.email ENDS WITH '@example.com'
RETURN u.name, u.email

-- Find .org domains
WHERE u.website ENDS WITH '.org'
```

### CONTAINS

```cypher
-- Search for substring
MATCH (u:User)
WHERE u.bio CONTAINS 'developer'
RETURN u.name

-- Multiple contains
WHERE u.bio CONTAINS 'developer' AND u.bio CONTAINS 'rust'
```

### Regular Expression

```cypher
-- Match email pattern
WHERE u.email =~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$'

-- Match phone number format
WHERE u.phone =~ '^\\d{3}-\\d{3}-\\d{4}$'

-- Case-insensitive (using flags)
WHERE u.name =~ '(?i)alice'
```

### Combining Operators

```cypher
-- Domain filtering
WHERE u.email ENDS WITH '.com' OR u.email ENDS WITH '.org'

-- Name search
WHERE u.name STARTS WITH 'A' AND u.name CONTAINS 'li'
```

## String Concatenation

Use the `+` operator to concatenate strings:

```cypher
-- Concatenate first and last name
RETURN u.first_name + ' ' + u.last_name AS full_name

-- Build email
RETURN u.username + '@example.com' AS email
```

## Case Sensitivity

String operations are **case-sensitive** by default:

```cypher
-- These are different
'Alice' <> 'alice'
'ALICE' <> 'Alice'
```

For case-insensitive comparison:

```cypher
-- Convert to lowercase first
WHERE LOWER(u.name) = LOWER('Alice')

-- Or use regex with flag
WHERE u.name =~ '(?i)alice'
```

## NULL Handling

String operators return NULL if any operand is NULL:

```cypher
-- NULL STARTS WITH 'A' = NULL
-- NULL CONTAINS 'x' = NULL
WHERE u.email IS NOT NULL AND u.email ENDS WITH '.com'
```

## Performance Considerations

| Operator | Performance | Index Usage |
|----------|-------------|-------------|
| `=` | O(1) with index | Uses hash index |
| `STARTS WITH` | O(n) | Can use B-tree index |
| `ENDS WITH` | O(n) | Full scan |
| `CONTAINS` | O(n) | Full scan |
| `=~` | O(n*m) | Full scan |

For large datasets, consider:
- Using `=` with indexes when possible
- Full-text search for complex text queries
- Normalizing data (lowercase) for case-insensitive search

## Escape Sequions

In string literals, use backslash to escape:

```cypher
-- Single quote in string
WHERE u.name = 'O\'Reilly'

-- Backslash
WHERE u.path = 'C:\\Users\\Alice'

-- Newline, tab
WHERE u.text = 'Line 1\nLine 2\tTabbed'
```

## See Also

- [String Functions](../api/cypher.md#string) — UPPER, LOWER, SUBSTRING, etc.
- [Comparison Operators](comparison.md) — General comparison
