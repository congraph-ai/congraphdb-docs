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
SET u:Active
```

### REMOVE

Remove properties and labels from nodes and relationships.

```cypher
-- Remove properties
MATCH (u:User {name: 'Alice'})
REMOVE u.age

-- Remove labels
MATCH (u:User {name: 'Alice'})
REMOVE u:Active
```

### MERGE

Match existing nodes or create new ones if they don't exist. Supports conditional updates with `ON MATCH` and `ON CREATE`.

```cypher
-- Basic MERGE
MERGE (u:User {name: 'Alice'})

-- MERGE with conditional updates
MERGE (u:User {name: 'Alice'})
ON CREATE SET u.created = timestamp(), u.age = 30
ON MATCH SET u.lastSeen = timestamp(), u.visitCount = coalesce(u.visitCount, 0) + 1
RETURN u
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

### Temporal

| Function | Description |
|----------|-------------|
| `date(string)` | Parse or create a date value |
| `datetime()` | Get current datetime |
| `datetime(string)` | Parse datetime string |
| `timestamp()` | Unix timestamp in milliseconds |
| `duration(string)` | Parse ISO 8601 duration |
| `duration.between(start, end)` | Calculate duration between two dates |

**Temporal examples:**

```cypher
-- Create dates
RETURN date('2024-03-15') AS today

-- Current datetime
RETURN datetime() AS now

-- Timestamp
RETURN timestamp() AS epoch_ms

-- Duration calculation
MATCH (u:User {name: 'Alice'})-[:KNOWS {since: date('2020-01-01')}]->(f:User)
RETURN duration.between(date('2020-01-01'), date()).years AS years_known
```

### Node and Label

| Function | Description |
|----------|-------------|
| `labels(node)` | Get all labels for a node |
| `has_label(node, label)` | Check if node has a specific label |

**Label examples:**

```cypher
-- Get all labels
MATCH (u:User {name: 'Alice'})
RETURN labels(u) AS all_labels

-- Filter by label presence
MATCH (u)
WHERE 'Admin' IN labels(u)
RETURN u.name

-- Multi-label node matching
MATCH (u:User:Admin:Premium)
RETURN u.name
```

### Path

| Function | Description |
|----------|-------------|
| `shortestPath(pattern)` | Find shortest path between nodes |
| `allShortestPaths(pattern)` | Find all shortest paths |
| `length(path)` | Get path length |
| `nodes(path)` | Get nodes in path |
| `relationships(path)` | Get relationships in path |
| `start_node(path)` | Get starting node |
| `end_node(path)` | Get ending node |

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

### CASE

Full conditional logic support in queries.

```cypher
-- Simple CASE expression
MATCH (u:User)
RETURN u.name,
  CASE u.age
    WHEN 18 THEN 'Adult'
    WHEN 65 THEN 'Senior'
    ELSE 'Other'
  END AS category

-- Generic CASE expression
MATCH (u:User)
RETURN u.name,
  CASE
    WHEN u.age < 18 THEN 'Minor'
    WHEN u.age >= 18 AND u.age < 65 THEN 'Adult'
    ELSE 'Senior'
  END AS life_stage
```

## Patterns

### Pattern Comprehensions

Create collections from graph patterns:

```cypher
-- Single-node comprehension
MATCH (u:User)
RETURN [(u)-[:FRIENDS_WITH]->(f) | f.name] AS friend_names

-- Relationship pattern with WHERE clause
MATCH (u:User)
RETURN [(u)-[:FRIENDS_WITH]->(f) WHERE f.age > 25 | f.name] AS older_friends

-- Multi-hop pattern comprehensions
MATCH (u:User)
RETURN [(u)-[:KNOWS]->(f)-[:FOLLOWS]->(ff) | ff.name] AS friends_of_friends

-- Outer variable scope
MATCH (u:User {name: 'Alice'})
WHERE u.age > 30
RETURN [(u)-[:KNOWS]->(f) WHERE f.age > u.age - 5 | f.name] AS peers
```

### Map Literals

Create maps (objects) in queries:

```cypher
-- Simple map
RETURN {name: 'Alice', age: 30, active: true} AS user_data

-- Map with expressions
MATCH (u:User)
RETURN {name: u.name, is_adult: u.age >= 18} AS user_info

-- Nested maps
MATCH (u:User)-[:KNOWS]->(f:User)
RETURN {
  user: u.name,
  friend: {
    name: f.name,
    age: f.age
  }
} AS relationship
```

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

Find the shortest path between two nodes:

```cypher
-- Basic shortest path
MATCH p = shortestPath(
  (a:User {name: 'Alice'})-[:KNOWS*]-(b:User {name: 'Bob'})
)
RETURN p

-- Limit path length
MATCH p = shortestPath(
  (a:User {name: 'Alice'})-[:KNOWS*..5]-(b:User {name: 'Bob'})
)
RETURN length(p) AS hops, [node IN nodes(p) | node.name] AS path

-- Get all shortest paths at minimum length
MATCH p = allShortestPaths(
  (a:User {name: 'Alice'})-[:KNOWS*..3]-(b:User {name: 'Bob'})
)
RETURN [node IN nodes(p) | node.name] AS path
```

**Relationship directions:**

```cypher
-- Outgoing only
MATCH p = shortestPath((a)-[:FOLLOWS*]->(b))

-- Incoming only
MATCH p = shortestPath((a)<-[:FOLLOWS*]-(b))

-- Undirected (any direction)
MATCH p = shortestPath((a)-[:KNOWS*]-(b))
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
- [Operators](../operators/index.md) — Detailed operator reference
