# Queries

CongraphDB uses **Cypher**, a graph query language that makes it easy to work with connected data.

## Basic Query Structure

```cypher
MATCH [pattern]
WHERE [conditions]
RETURN [expressions]
```

## MATCH Clause

Find nodes and relationships in your graph.

### Find All Nodes

```javascript
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.age
`);
```

### Find Relationships

```javascript
const result = await conn.query(`
  MATCH (u:User)-[k:Knows]->(f:User)
  RETURN u.name AS user, f.name AS friend, k.since
`);
```

### Filter with WHERE

```javascript
const result = await conn.query(`
  MATCH (u:User)
  WHERE u.age > 25
  RETURN u.name, u.age
`);
```

## CREATE Clause

Create new nodes and relationships.

### Create a Node

```javascript
await conn.query(`
  CREATE (u:User {name: 'Charlie', age: 35})
`);
```

### Create Nodes with Relationships

```javascript
await conn.query(`
  CREATE (alice:User {name: 'Alice', age: 30})
         -[:Knows {since: 2020}]->
         (bob:User {name: 'Bob', age: 25})
`);
```

### Create Relationship Between Existing Nodes

```javascript
await conn.query(`
  MATCH (alice:User {name: 'Alice'})
  MATCH (bob:User {name: 'Bob'})
  CREATE (alice)-[:Knows {since: 2020}]->(bob)
`);
```

## Variable-Length Paths

Find patterns with varying relationship lengths.

```javascript
// Friends of friends (1 to 3 hops)
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})-[:Knows*1..3]->(f:User)
  RETURN DISTINCT f.name
`);
```

## Aggregation

```javascript
// Count friends per user
const result = await conn.query(`
  MATCH (u:User)-[:Knows]->(f:User)
  RETURN u.name, COUNT(f) AS friend_count
`);

// Average age by user
const result = await conn.query(`
  MATCH (u:User)-[:Knows]->(f:User)
  RETURN u.name, AVG(f.age) AS avg_friend_age
`);
```

## Ordering and Limiting

```javascript
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.age
  ORDER BY u.age DESC
  LIMIT 10
`);
```

## DELETE Clause

Remove nodes and relationships.

```javascript
// Delete a relationship
await conn.query(`
  MATCH (u:User {name: 'Alice'})-[k:Knows]->(f:User {name: 'Bob'})
  DELETE k
`);

// Delete a node and its relationships
await conn.query(`
  MATCH (u:User {name: 'Bob'})
  DETACH DELETE u
`);
```

## SET Clause

Update properties.

```javascript
await conn.query(`
  MATCH (u:User {name: 'Alice'})
  SET u.age = 31
`);
```

## Pattern Comprehensions

Pattern comprehensions allow you to create collections from patterns in your graph. They're useful for extracting related data into lists.

### Single-Node Pattern Comprehensions

```javascript
// Collect names of all friends
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})
  RETURN [(u)-[:KNOWS]->(f) | f.name] AS friend_names
`);
// Result: { friend_names: ['Bob', 'Charlie', 'David'] }
```

### Relationship Patterns

```javascript
// Collect friend names with additional filtering
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})
  RETURN [(u)-[:KNOWS]->(f) WHERE f.age > 25 | f.name] AS older_friends
`);
// Result: { older_friends: ['Bob', 'Charlie'] }
```

### Multi-Hop Patterns

```javascript
// Collect friends of friends
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})
  RETURN [(u)-[:KNOWS]->(f)-[:KNOWS]->(ff) | ff.name] AS friends_of_friends
`);
```

### Outer Variable Scope

Pattern comprehensions can reference variables from the outer query context:

```javascript
// Filter comprehension using outer variable
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})
  WHERE u.age > 30
  RETURN [(u)-[:KNOWS]->(f) WHERE f.age > u.age - 5 | f.name] AS peers
`);
```

### Nested Comprehensions

```javascript
// Get friends with their friends
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})
  RETURN [
    (u)-[:KNOWS]->(f) |
    { name: f.name, friends: [(f)-[:KNOWS]->(ff) | ff.name] }
  ] AS social_network
`);
```

## Temporal Types

CongraphDB supports temporal types for working with dates and times.

### Date Type

```javascript
// Create a date
const result = await conn.query(`
  RETURN date('2024-03-15') AS today
`);
// Result: { today: '2024-03-15' }

// Use in WHERE clause
await conn.query(`
  MATCH (e:Event)
  WHERE e.date >= date('2024-01-01')
  RETURN e.title
`);
```

### DateTime Type

```javascript
// Current datetime
const result = await conn.query(`
  RETURN datetime() AS now
`);

// Parse datetime string
const result = await conn.query(`
  RETURN datetime('2024-03-15T10:30:00') AS meeting_time
`);

// Compare datetimes
await conn.query(`
  MATCH (o:Order)
  WHERE o.created_at > datetime('2024-03-01T00:00:00')
  RETURN o.id
`);
```

### Duration Type

```javascript
// Parse duration
const result = await conn.query(`
  RETURN duration('P1DT2H30M') AS time_span
`);
// Result: 1 day, 2 hours, 30 minutes

// Calculate duration between dates
await conn.query(`
  MATCH (u:User {name: 'Alice'})-[:KNOWS {since: date('2020-01-01')}]->(f:User)
  RETURN duration.between(date('2020-01-01'), date()).years AS years_known
`);
```

### Temporal Functions Reference

| Function | Description | Example |
|----------|-------------|---------|
| `date(string)` | Parse or create date | `date('2024-03-15')` |
| `datetime()` | Get current datetime | `datetime()` |
| `datetime(string)` | Parse datetime string | `datetime('2024-03-15T10:30:00')` |
| `timestamp()` | Unix timestamp in ms | `timestamp()` |
| `duration(string)` | Parse ISO 8601 duration | `duration('P1D')` |

## Map Literals

Create maps (objects) directly in your queries:

```javascript
// Create a map literal
const result = await conn.query(`
  RETURN {name: 'Alice', age: 30, active: true} AS user_data
`);
// Result: { user_data: { name: 'Alice', age: 30, active: true } }

// Use with pattern comprehensions
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})-[:KNOWS]->(f:User)
  RETURN {
    name: f.name,
    age: f.age,
    is_adult: f.age >= 18
  } AS friend_info
`);
```

## Multi-Label Nodes

Nodes can have multiple labels for categorization:

```javascript
// Create node with multiple labels
await conn.query(`
  CREATE (u:User:Admin:Premium {name: 'Alice', role: 'admin'})
`);

// Query by multiple labels
await conn.query(`
  MATCH (u:User:Admin)
  RETURN u.name
`);

// Get all labels for a node
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})
  RETURN labels(u) AS all_labels
`);
// Result: { all_labels: ['User', 'Admin', 'Premium'] }

// Filter by label presence
await conn.query(`
  MATCH (u)
  WHERE 'Admin' IN labels(u)
  RETURN u.name
`);
```

## Path Finding Functions

### shortestPath()

Find the shortest path between two nodes:

```javascript
// Basic shortest path
const result = await conn.query(`
  MATCH p = shortestPath(
    (alice:User {name: 'Alice'})-[:KNOWS*]-(bob:User {name: 'Bob'})
  )
  RETURN [node IN nodes(p) | node.name] AS path
`);
// Result: { path: ['Alice', 'Charlie', 'Bob'] }

// Limit path length
const result = await conn.query(`
  MATCH p = shortestPath(
    (alice:User {name: 'Alice'})-[:KNOWS*..5]-(bob:User {name: 'Bob'})
  )
  RETURN length(p) AS hops, [node IN nodes(p) | node.name] AS path
`);
```

### allShortestPaths()

Find all shortest paths at minimum length:

```javascript
// Find all shortest paths
const result = await conn.query(`
  MATCH p = allShortestPaths(
    (alice:User {name: 'Alice'})-[:KNOWS*..3]-(bob:User {name: 'Bob'})
  )
  RETURN [node IN nodes(p) | node.name] AS path
`);
// Returns multiple rows, one for each shortest path
```

### Relationship Directions

```javascript
// Outgoing only
MATCH p = shortestPath((a)-[:FOLLOWS*]->(b))

// Incoming only
MATCH p = shortestPath((a)<-[:FOLLOWS*]-(b))

// Undirected (any direction)
MATCH p = shortestPath((a)-[:KNOWS*]-(b))
```

## Complete Examples

### Social Network Query

```javascript
// Find users who know someone named 'Alice'
const result = await conn.query(`
  MATCH (u:User)-[:Knows]->(alice:User {name: 'Alice'})
  RETURN u.name, u.email
`);
```

### Recommendation Query

```javascript
// Recommend friends: friends of friends I don't know yet
const result = await conn.query(`
  MATCH (me:User {name: 'Alice'})-[:Knows]->(friend)-[:Knows]->(foaf:User)
  WHERE NOT (me)-[:Knows]->(foaf) AND me <> foaf
  RETURN foaf.name, COUNT(friend) AS mutual_friends
  ORDER BY mutual_friends DESC
  LIMIT 10
`);
```

### Shortest Path

```javascript
// Find shortest path between two users
const result = await conn.query(`
  MATCH p=shortestPath(
    (alice:User {name: 'Alice'})-[:Knows*]-(bob:User {name: 'Bob'})
  )
  RETURN [node IN nodes(p) | node.name] AS path
`);
```

## Working with Results

```javascript
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.age
`);

// Get all rows at once
const rows = result.getAll();
for (const row of rows) {
  console.log(row);
}

// Iterate row by row (streaming)
while (result.hasMore()) {
  const row = result.getNext();
  console.log(row);
}

// Get column information
console.log(result.getColumnNames());  // ['u.name', 'u.age']
console.log(result.getColumnDataTypes());  // ['STRING', 'INT64']

// Always close when done
result.close();
```

## Next Steps

- [Transactions](transactions.md) — Group operations into transactions
- [Vector Search](vector-search.md) — Semantic search with embeddings
