# Cypher Reference

CongraphDB implements a subset of the Cypher graph query language.

## Clauses

### MATCH

Find patterns in the graph.

```cypher
MATCH (u:User)
MATCH (u:User)-[:KNOWS]->(f:User)
MATCH (u:User {name: 'Alice'})-[:KNOWS]->(f:User)
```

### RETURN

Specify what to return from the query.

```cypher
RETURN u.name, u.age
RETURN u.name AS username, COUNT(*) AS count
RETURN DISTINCT u.city
```

### WHERE

Filter results.

```cypher
WHERE u.age > 25
WHERE u.name = 'Alice' OR u.name = 'Bob'
WHERE u.name STARTS WITH 'A'
WHERE u.name IN ['Alice', 'Bob', 'Charlie']
```

### CREATE

Create new nodes and relationships.

```cypher
CREATE (u:User {name: 'Alice', age: 30})
CREATE (u:User)-[:KNOWS {since: 2020}]->(f:User)
```

### DELETE

Remove nodes and relationships.

```cypher
DELETE r
DELETE u
DETACH DELETE u
```

### SET

Update properties.

```cypher
SET u.age = 31
SET u.age = u.age + 1
SET u:Active
```

## Operators

### Comparison

| Operator | Description |
|----------|-------------|
| `=` | Equal |
| `<>` or `!=` | Not equal |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

### Logical

| Operator | Description |
|----------|-------------|
| `AND` | Logical and |
| `OR` | Logical or |
| `NOT` | Logical not |
| `XOR` | Exclusive or |

### String

| Operator | Description |
|----------|-------------|
| `STARTS WITH` | String starts with prefix |
| `ENDS WITH` | String ends with suffix |
| `CONTAINS` | String contains substring |
| `=~` | Regular expression match |

### Arithmetic

| Operator | Description |
|----------|-------------|
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `%` | Modulo |
| `^` | Exponentiation |

### Vector

| Operator | Description |
|----------|-------------|
| `<->` | Cosine distance (recommended for embeddings) |
| `<=>` | Euclidean distance (L2) |
| `<=` | Negative inner product |

## Functions

### Aggregate

| Function | Description |
|----------|-------------|
| `COUNT(*)` | Count rows |
| `COUNT(expr)` | Count non-null values |
| `SUM(expr)` | Sum of values |
| `AVG(expr)` | Average of values |
| `MIN(expr)` | Minimum value |
| `MAX(expr)` | Maximum value |
| `COLLECT(expr)` | Collect into array |

### String

| Function | Description |
|----------|-------------|
| `toString(expr)` | Convert to string |
| `UPPER(string)` | Uppercase |
| `LOWER(string)` | Lowercase |
| `SUBSTRING(string, start, length)` | Extract substring |
| `LENGTH(string)` | String length |
| `TRIM(string)` | Remove whitespace |

### Mathematical

| Function | Description |
|----------|-------------|
| `ABS(expr)` | Absolute value |
| `CEIL(expr)` | Round up |
| `FLOOR(expr)` | Round down |
| `ROUND(expr)` | Round to nearest |
| `SQRT(expr)` | Square root |
| `POW(base, exp)` | Power |
| `LOG(expr)` | Natural logarithm |
| `LOG10(expr)` | Base-10 logarithm |
| `EXP(expr)` | Exponential |
| `SIN(expr)` | Sine |
| `COS(expr)` | Cosine |
| `TAN(expr)` | Tangent |

### List

| Function | Description |
|----------|-------------|
| `size(list)` | List length |
| `head(list)` | First element |
| `last(list)` | Last element |
| `tail(list)` | All but first element |
| `[elem IN list WHERE predicate]` | List comprehension |
| `extract(var IN list | expr)` | Transform list |

## Patterns

### Variable-Length Paths

```cypher
-- 1 to 3 hops
(u)-[:KNOWS*1..3]->(v)

-- Any length
(u)-[:KNOWS*]->(v)

-- Exactly 2 hops
(u)-[:KNOWS*2]->(v)
```

### Shortest Path

```cypher
MATCH p = shortestPath(
  (a:User {name: 'Alice'})-[:KNOWS*]-(b:User {name: 'Bob'})
)
RETURN p
```

### Optional Match

```cypher
MATCH (u:User)
OPTIONAL MATCH (u)-[:KNOWS]->(f:User)
RETURN u.name, f.name
```

## Parameters

Use parameters to avoid Cypher injection and improve performance:

```javascript
// Named parameters
await conn.query(`
  MATCH (u:User {name: $name})
  RETURN u
`, { name: 'Alice' });

// Numbered parameters
await conn.query(`
  MATCH (u:User {name: $1})
  RETURN u
`, ['Alice']);
```

## Examples

### Find friends of friends

```cypher
MATCH (me:User {name: 'Alice'})-[:KNOWS]->(friend)-[:KNOWS]->(foaf:User)
WHERE NOT (me)-[:KNOWS]->(foaf) AND me <> foaf
RETURN foaf.name, COUNT(friend) AS mutual_friends
ORDER BY mutual_friends DESC
LIMIT 10
```

### Find users by age range

```cypher
MATCH (u:User)
WHERE u.age >= 25 AND u.age < 35
RETURN u.name, u.age
ORDER BY u.age
```

### Vector similarity search

```cypher
MATCH (d:Document)
RETURN d.title, d.embedding <-> $query AS distance
ORDER BY distance
LIMIT 5
```

### Aggregation

```cypher
MATCH (u:User)-[:KNOWS]->(f:User)
RETURN u.name, COUNT(f) AS friend_count, AVG(f.age) AS avg_friend_age
ORDER BY friend_count DESC
```

## See Also

- [Queries Guide](../guide/queries.md) — Query examples and patterns
- [Operators](../operators/) — Detailed operator reference
