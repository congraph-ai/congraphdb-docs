# Queries

CongraphDB provides **three ways to query your graph**:

1. **Cypher Query Language** (below) - Industry-standard graph query language
2. **JavaScript Native API** - Programmatic interface for CRUD operations
3. **Navigator API** - Fluent graph traversal API

This page covers the Cypher query language. For JavaScript API queries, see [JavaScript API Queries](#javascript-api-queries) below, or the [JavaScript API Reference](../api/javascript-api.md).

---

## Cypher Query Language

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

## CASE Expressions

CongraphDB supports `CASE` expressions for conditional logic within your queries.

### Simple CASE

```javascript
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name,
    CASE u.age
      WHEN 18 THEN 'Adult'
      WHEN 65 THEN 'Senior'
      ELSE 'Other'
    END AS status
`);
```

### Generic CASE

```javascript
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name,
    CASE
      WHEN u.age < 18 THEN 'Minor'
      WHEN u.age >= 18 AND u.age < 65 THEN 'Adult'
      ELSE 'Senior'
    END AS life_stage
`);
```

## Ordering and Limiting

CongraphDB supports `ORDER BY`, `SKIP`, and `LIMIT` clauses for controlling query results.

### ORDER BY

Sort results by one or more columns:

```javascript
// Sort by single column (descending)
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.age
  ORDER BY u.age DESC
`);

// Sort by multiple columns
const result = await conn.query(`
  MATCH (p:Post)
  RETURN p.title, p.created, p.author
  ORDER BY p.created DESC, p.title ASC
`);

// Sort with aggregation
const result = await conn.query(`
  MATCH (u:User)-[:KNOWS]->(f:User)
  RETURN u.name, COUNT(f) AS friend_count
  ORDER BY friend_count DESC
`);
```

### SKIP and LIMIT

Paginate through results:

```javascript
// Basic pagination (skip first 10, get next 20)
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.age
  ORDER BY u.name
  SKIP 10 LIMIT 20
`);

// Get top N results
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.score
  ORDER BY u.score DESC
  LIMIT 10
`);

// Combined pagination
const page = 2;
const pageSize = 25;
const result = await conn.query(`
  MATCH (p:Post)
  RETURN p.title
  ORDER BY p.created DESC
  SKIP ${page * pageSize} LIMIT ${pageSize}
`);
```

## UNION

Combine results from multiple MATCH patterns using the `UNION` operator. This is useful when you need to merge results from different query patterns.

### Basic UNION

```javascript
// Union of two relationship types
const result = await conn.query(`
  MATCH (u:User)-[:FOLLOWS]->(f:User)
  RETURN u.name AS name, f.name AS value
  UNION
  MATCH (u:User)-[:KNOWS]->(k:User)
  RETURN u.name AS name, k.name AS value
`);
```

### UNION with Different Node Types

```javascript
// Find contacts from different entity types
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name AS name, u.email AS contact, 'User' AS type
  UNION
  MATCH (o:Organization)
  RETURN o.name AS name, o.website AS contact, 'Organization' AS type
`);
```

### UNION with Aggregations

```javascript
// Combine different counts
const result = await conn.query(`
  MATCH (u:User)-[:POSTED]->(:Post)
  RETURN u.name AS name, COUNT(*) AS count, 'Posts' AS source
  UNION
  MATCH (u:User)-[:COMMENTED]->(:Comment)
  RETURN u.name AS name, COUNT(*) AS count, 'Comments' AS source
  ORDER BY count DESC
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

## REMOVE Clause

Remove properties and labels from nodes and relationships.

```javascript
// Remove a property
await conn.query(`
  MATCH (u:User {name: 'Alice'})
  REMOVE u.age
`);

// Remove a label
await conn.query(`
  MATCH (u:User {name: 'Alice'})
  REMOVE u:Active
`);
```

## MERGE Clause

Match existing nodes or create new ones if they don't exist. Supports conditional updates with `ON MATCH` and `ON CREATE`.

```javascript
// Basic MERGE
await conn.query(`
  MERGE (u:User {name: 'Alice'})
`);

// MERGE with conditional updates
await conn.query(`
  MERGE (u:User {name: 'Alice'})
  ON CREATE SET u.created = timestamp(), u.age = 30
  ON MATCH SET u.lastSeen = timestamp(), u.visitCount = coalesce(u.visitCount, 0) + 1
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

### Query Execution Statistics

CongraphDB tracks performance metrics for every query execution. You can access these via the `statistics` property.

```javascript
const result = await conn.query("MATCH (u:User) RETURN u.name");

console.log(result.statistics);
// Output:
// {
//   query: "MATCH (u:User) RETURN u.name",
//   execution_time_ms: 0.12,
//   row_count: 5,
//   query_type: "MATCH"
// }
```

| Metric | Description |
|--------|-------------|
| `query` | The original query string |
| `execution_time_ms` | Time taken to execute (excluding network/FFI overhead) |
| `row_count` | Number of rows in the result set |
| `query_type` | Type of query (MATCH, CREATE, DELETE, etc.) |

---

## JavaScript API Queries

CongraphDB's JavaScript Native API provides a programmatic alternative to Cypher for many common operations. This is especially useful for:

- Simple CRUD operations
- Application-specific data access
- Type safety with TypeScript
- Developers who prefer method calls over query strings

### CRUD Operations

#### Create Nodes

```javascript
const { Database, CongraphDBAPI } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);

// Create a node
const alice = await api.createNode('User', {
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
});
// Returns: { _id: '...', name: 'Alice', age: 30, email: '...' }
```

#### Create Relationships

```javascript
const bob = await api.createNode('User', {
  name: 'Bob',
  age: 25
});

await api.createEdge(alice._id, 'KNOWS', bob._id, {
  since: 2020
});
```

#### Read Nodes

```javascript
// Get by ID
const node = await api.getNode(alice._id);

// Get all nodes by label
const users = await api.getNodesByLabel('User');
```

#### Update Nodes

```javascript
const updated = await api.updateNode(alice._id, {
  age: 31,
  lastSeen: Date.now()
});
```

#### Delete Nodes

```javascript
// Delete without relationships
await api.deleteNode(alice._id);

// Delete with relationships (detach)
await api.deleteNode(alice._id, true);
```

### Pattern Matching Queries

The `find()` method provides declarative pattern matching similar to graph triple stores.

#### Basic Pattern Matching

```javascript
// Find Alice's friends
const friends = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
});

// Results: [{ friend: { name: 'Bob', age: 25, ... } }, ...]
```

#### Pattern with Variables

```javascript
// Find all KNOWS relationships
const relationships = await api.find({
  subject: api.v('person'),
  predicate: 'KNOWS',
  object: api.v('friend')
});

// Results: [
//   { person: { name: 'Alice', ... }, friend: { name: 'Bob', ... } },
//   ...
// ]
```

#### Filtered Pattern Matching

```javascript
// Find friends over age 25
const friends = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
}, {
  where: 'friend.age > 25'
});
```

### Navigator Traversal Queries

The Navigator API provides fluent chaining for graph traversal, ideal for multi-hop queries.

#### One-Hop Traversal

```javascript
// Find Alice's friends
const friends = await api.nav(alice._id)
  .out('KNOWS')
  .values();
```

#### Multi-Hop Traversal

```javascript
// Friends of friends
const friendsOfFriends = await api.nav(alice._id)
  .out('KNOWS')
  .out('KNOWS')
  .values();
```

#### Bidirectional Traversal

```javascript
// All connections (incoming and outgoing)
const connections = await api.nav(alice._id)
  .both('KNOWS')
  .values();
```

#### Filtered Traversal

```javascript
// Friends in specific city
const nycFriends = await api.nav(alice._id)
  .out('KNOWS')
  .where('city = "NYC"')
  .values();

// Or with JavaScript function
const youngFriends = await api.nav(alice._id)
  .out('KNOWS')
  .where(f => f.age < 30)
  .values();
```

#### Limited Results

```javascript
// First 5 friends
const firstFive = await api.nav(alice._id)
  .out('KNOWS')
  .limit(5)
  .values();
```

#### Counting Results

```javascript
// Count friends without retrieving all data
const count = await api.nav(alice._id)
  .out('KNOWS')
  .count();
```

#### Path Finding

```javascript
// Find shortest path to Bob
const path = await api.nav(alice._id)
  .out('KNOWS')
  .to(bob._id)
  .values();
```

### Edge Queries

```javascript
// Get all edges from a node
const outgoing = await api.getEdges({ from: alice._id });

// Get all edges to a node
const incoming = await api.getEdges({ to: alice._id });

// Get edges by type
const knowsEdges = await api.getEdges({ type: 'KNOWS' });

// Combined filters
const results = await api.getEdges({
  from: alice._id,
  type: 'KNOWS'
});
```

### Transaction Queries

```javascript
await api.transaction(async (txApi) => {
  const alice = await txApi.createNode('User', { name: 'Alice' });
  const bob = await txApi.createNode('User', { name: 'Bob' });
  await txApi.createEdge(alice._id, 'KNOWS', bob._id);
  // All operations commit if no error is thrown
});
```

### Async Iteration

```javascript
// Iterate over results
for await (const friend of api.nav(alice._id).out('KNOWS')) {
  console.log(friend.name);
}
```

### Comparison: Cypher vs JavaScript API vs Navigator

| Operation | Cypher | JavaScript API | Navigator |
|-----------|--------|----------------|-----------|
| **Find Alice's friends** | `MATCH (a:User {name: 'Alice'})-[:KNOWS]->(f) RETURN f` | `api.find({subject: alice._id, predicate: 'KNOWS', object: api.v('f')})` | `api.nav(alice._id).out('KNOWS').values()` |
| **Friends of friends** | `MATCH (a)-[:KNOWS]->()-[:KNOWS]->(f) RETURN f` | Chain `find()` calls | `api.nav(id).out('KNOWS').out('KNOWS').values()` |
| **Filter results** | `WHERE f.age > 25` | `where: 'f.age > 25'` | `.where(f => f.age > 25)` |
| **Limit results** | `LIMIT 10` | Manual filtering | `.limit(10)` |
| **Create node** | `CREATE (u:User {...})` | `api.createNode('User', {...})` | N/A |
| **Delete node** | `DETACH DELETE u` | `api.deleteNode(id, true)` | N/A |
| **Shortest path** | `shortestPath((a)-[*]-(b))` | Use Cypher | `.to(targetId).values()` |

### When to Use Each Interface

**Use Cypher for:**
- Complex multi-hop queries with conditions
- Aggregations and analytics
- Pattern comprehensions
- Complex filtering and sorting

**Use JavaScript API (find) for:**
- Simple pattern matching
- When you need variable binding
- Programmatic query building

**Use Navigator for:**
- Multi-hop traversals
- Fluent chaining
- Path finding
- When code readability is important

**Use JavaScript API (CRUD) for:**
- Create, read, update, delete operations
- Application-specific data access
- When you want type safety

For a detailed decision guide, see [Choosing Your Query Interface](choosing-interface.md).

---

## Next Steps

- [Transactions](transactions.md) — Group operations into transactions
- [Vector Search](vector-search.md) — Semantic search with embeddings
