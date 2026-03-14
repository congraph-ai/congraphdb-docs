# Logical Operators

Boolean operators for combining conditions.

## Operators

| Operator | Description | Precedence |
|----------|-------------|------------|
| `AND` | Logical AND | High |
| `OR` | Logical OR | Low |
| `NOT` | Logical NOT | Highest |
| `XOR` | Exclusive OR | Medium |

## Truth Table

| A | B | A AND B | A OR B | A XOR B | NOT A |
|---|---|---------|--------|---------|-------|
| true | true | true | true | false | false |
| true | false | false | true | true | false |
| false | true | false | true | true | true |
| false | false | false | false | false | true |

## Examples

### AND

```cypher
-- Find users who are adults and live in NY
MATCH (u:User)
WHERE u.age >= 18 AND u.city = 'New York'
RETURN u
```

### OR

```cypher
-- Find users who live in NY or LA
MATCH (u:User)
WHERE u.city = 'New York' OR u.city = 'Los Angeles'
RETURN u
```

### NOT

```cypher
-- Find users who don't have an email
MATCH (u:User)
WHERE NOT u.email IS NOT NULL
RETURN u

-- Alternative
WHERE u.email IS NULL
```

### Combining Operators

```cypher
-- Complex condition
WHERE (u.city = 'NY' OR u.city = 'LA')
  AND u.age >= 21
  AND NOT u.status = 'inactive'
```

### XOR

```cypher
-- Users who have email OR phone, but not both
WHERE (u.email IS NOT NULL) XOR (u.phone IS NOT NULL)
```

## Operator Precedence

When mixing operators, use parentheses for clarity:

```cypher
-- Ambiguous (depends on precedence)
WHERE u.age > 25 OR u.city = 'NY' AND u.status = 'active'

-- Clear (recommended)
WHERE (u.age > 25) OR (u.city = 'NY' AND u.status = 'active')
```

Precedence (highest to lowest):
1. `NOT`
2. `AND`
3. `XOR`
4. `OR`

## Short-Circuit Evaluation

CongraphDB uses short-circuit evaluation:

```cypher
-- If u.age is NULL, u.age > 25 is not evaluated
WHERE u.name IS NOT NULL AND u.age > 25
```

## Null Handling

Logical operators handle NULL specially:

| Expression | Result |
|------------|--------|
| `NULL AND true` | NULL |
| `NULL AND false` | false |
| `NULL OR true` | true |
| `NULL OR false` | NULL |
| `NOT NULL` | NULL |

## See Also

- [Comparison Operators](comparison.md) — Equality and ordering
- [WHERE Clause](../api/cypher.md) — Filtering queries
