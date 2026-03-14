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
