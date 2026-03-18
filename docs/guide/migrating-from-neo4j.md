# Migrating from Neo4j

CongraphDB uses **Cypher**, the same query language as Neo4j, making migration from Neo4j straightforward. This guide covers the key differences and how to migrate your applications.

## Quick Comparison

| Feature | Neo4j | CongraphDB |
|---------|-------|------------|
| **Query Language** | Cypher | Cypher (compatible subset) |
| **Deployment** | Server/Client | Embedded (serverless) |
| **Storage** | Separate database files | Single `.cgraph` file |
| **Driver** | Bolt protocol | Native Node.js bindings |
| **Transactions** | `session.beginTransaction()` | `conn.beginTransaction()` |
| **JavaScript Driver** | `neo4j-driver` | `congraphdb` |

## Installation Change

### Neo4j Driver
```javascript
npm install neo4j-driver
```

```javascript
const neo4j = require('neo4j-driver');
const driver = neo4j.driver('bolt://localhost:7687');
const session = driver.session();
```

### CongraphDB
```javascript
npm install congraphdb
```

```javascript
const { Database } = require('congraphdb');
const db = new Database('./my-graph.cgraph');
db.init();
const conn = db.createConnection();
```

## Driver API vs Native API

### Running Queries

#### Neo4j Driver
```javascript
const result = await session.run(`
  MATCH (u:User {name: $name}) RETURN u
`, { name: 'Alice' });

const records = result.records;
const single = result.records[0].get('u');
```

#### CongraphDB
```javascript
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'}) RETURN u
`);

const rows = result.getAll();
const single = rows[0].u;
```

### Transactions

#### Neo4j Driver
```javascript
const txc = await session.beginTransaction();
try {
  await txc.run(`CREATE (u:User {name: 'Alice'})`);
  await txc.run(`CREATE (u:User {name: 'Bob'})`);
  await txc.commit();
} catch (error) {
  await txc.rollback();
  throw error;
}
```

#### CongraphDB
```javascript
conn.beginTransaction();
try {
  await conn.query(`CREATE (u:User {name: 'Alice'})`);
  await conn.query(`CREATE (u:User {name: 'Bob'})`);
  conn.commit();
} catch (error) {
  conn.rollback();
  throw error;
}
```

## Schema Definition

### Neo4j (Schema-less)
```javascript
// Neo4j doesn't require schema definition
// Nodes and relationships are created on-the-fly
await session.run(`
  CREATE (u:User {name: 'Alice', email: 'alice@example.com'})
`);
```

### CongraphDB (Schema Required)
```javascript
// CongraphDB requires schema definition first
await conn.query(`
  CREATE NODE TABLE User (
    id STRING,
    name STRING,
    email STRING,
    PRIMARY KEY (id)
  )
`);

await conn.query(`
  CREATE REL TABLE KNOWS (
    FROM User TO User,
    since INT64
  )
`);

// Then insert data
await conn.query(`
  CREATE (u:User {id: 'alice', name: 'Alice', email: 'alice@example.com'})
`);
```

## Schema Migration

### Converting Implicit Schema to Explicit Schema

If you have an existing Neo4j database, you'll need to define a schema for CongraphDB:

#### Step 1: Identify Node Labels and Properties

```cypher
// In Neo4j, identify your node types
MATCH (n)
RETURN DISTINCT labels(n) AS labels, keys(n) AS properties
```

#### Step 2: Define Node Tables

For each node label, create a table:

```javascript
// Based on your Neo4j labels
await conn.query(`
  CREATE NODE TABLE User (
    id STRING,
    name STRING,
    email STRING,
    age INT64,
    PRIMARY KEY (id)
  )
`);

await conn.query(`
  CREATE NODE TABLE Product (
    id STRING,
    name STRING,
    price INT64,
    category STRING,
    PRIMARY KEY (id)
  )
`);
```

#### Step 3: Identify Relationship Types

```cypher
// In Neo4j, identify relationship types
MATCH ()-[r]->()
RETURN DISTINCT type(r) AS relType, keys(r) AS properties
```

#### Step 4: Define Relationship Tables

```javascript
await conn.query(`
  CREATE REL TABLE KNOWS (
    FROM User TO User,
    since INT64
  )
`);

await conn.query(`
  CREATE REL TABLE PURCHASED (
    FROM User TO Product,
    date DATE,
    quantity INT64
  )
`);
```

## Data Migration

### Export from Neo4j

```cypher
// Export users
MATCH (u:User)
RETURN u.id AS id, u.name AS name, u.email AS email, u.age AS age
```

### Import to CongraphDB

```javascript
// Import data
for (const user of neo4jUsers) {
  await conn.query(`
    CREATE (u:User {id: '${user.id}', name: '${user.name}', email: '${user.email}', age: ${user.age}})
  `);
}
```

### Bulk Import Example

```javascript
// Using JavaScript API for faster imports
const { Database, CongraphDBAPI } = require('congraphdb');

const db = new Database('./imported-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);

// Batch import nodes
const batchSize = 1000;
for (let i = 0; i < users.length; i += batchSize) {
  const batch = users.slice(i, i + batchSize);
  await Promise.all(batch.map(user =>
    api.createNode('User', user)
  ));
}

// Import relationships
for (const rel of relationships) {
  await api.createEdge(rel.from, rel.type, rel.to, rel.properties);
}
```

## Cypher Compatibility

### Supported Cypher Features

CongraphDB supports most commonly used Cypher features:

| Feature | Status | Notes |
|---------|--------|-------|
| MATCH | ✅ | Full support |
| CREATE | ✅ | Nodes and relationships |
| SET | ✅ | Including dynamic properties |
| DELETE | ✅ | Including DETACH DELETE |
| MERGE | ✅ | With ON CREATE / ON MATCH |
| WHERE | ✅ | Including property filters |
| ORDER BY | ✅ | Multiple columns |
| SKIP / LIMIT | ✅ | Pagination |
| DISTINCT | ✅ | Deduplication |
| Aggregations | ✅ | COUNT, SUM, AVG, MIN, MAX |
| Pattern comprehensions | ✅ | `[(pattern) \| expr]` |
| Path functions | ✅ | shortestPath, allShortestPaths |
| Temporal types | ✅ | DATE, DATETIME, DURATION |
| CASE expressions | ✅ | WHEN/THEN/ELSE |
| Regex matching | ✅ | =~ operator |

### Unsupported Features (as of v0.1.5)

| Feature | Status | Alternative |
|---------|--------|-------------|
| OPTIONAL MATCH | ⚠️ Partial | Use Navigator API or subqueries |
| CALL {} procedures | ❌ | Not supported |
| FOREACH | ❌ | Use JavaScript loops |
| LOAD CSV | ❌ | Use Node.js fs module |
| PERIODIC COMMIT | ❌ | Batch with JavaScript |
| UNION | ❌ | Multiple queries |
| Constraint syntax | ❌ | Use PRIMARY KEY in CREATE NODE TABLE |
| Index syntax | ❌ | Implicit indexes |

## Query Migration Examples

### Example 1: Simple Match

#### Neo4j
```javascript
const result = await session.run(`
  MATCH (u:User {name: 'Alice'})-[:KNOWS]->(f:User)
  RETURN f.name AS friend
`);
```

#### CongraphDB
```javascript
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})-[:KNOWS]->(f:User)
  RETURN f.name AS friend
`);
```

### Example 2: Parameterized Query

#### Neo4j Driver
```javascript
const result = await session.run(`
  MATCH (u:User {name: $name}) RETURN u
`, { name: 'Alice' });
```

#### CongraphDB
```javascript
// Note: Parameters not yet supported in v0.1.5
// Use string interpolation or the JavaScript API
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'}) RETURN u
`);
```

### Example 3: Path Finding

#### Neo4j
```javascript
const result = await session.run(`
  MATCH p = shortestPath(
    (a:User {name: 'Alice'})-[:KNOWS*]-(b:User {name: 'Charlie'})
  )
  RETURN p
`);
```

#### CongraphDB
```javascript
const result = await conn.query(`
  MATCH p = shortestPath(
    (a:User {name: 'Alice'})-[:KNOWS*]-(b:User {name: 'Charlie'})
  )
  RETURN p
`);
```

## Application Architecture Changes

### Connection Management

#### Neo4j (Client-Server)
```javascript
// Long-lived driver, short-lived sessions
const driver = neo4j.driver('bolt://localhost:7687');

async function handleRequest() {
  const session = driver.session();
  try {
    const result = await session.run('MATCH ...');
    return result.records;
  } finally {
    await session.close();
  }
}
```

#### CongraphDB (Embedded)
```javascript
// Long-lived database, create connections as needed
const db = new Database('./my-graph.cgraph');
db.init();

async function handleRequest() {
  const conn = db.createConnection();
  try {
    const result = await conn.query('MATCH ...');
    return result.getAll();
  } finally {
    // Connection doesn't need explicit close
  }
}
```

### Using the JavaScript API (CongraphDB Exclusive)

CongraphDB provides a JavaScript Native API that Neo4j doesn't have:

```javascript
const { Database, CongraphDBAPI } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);

// Type-safe CRUD operations
const alice = await api.createNode('User', {
  name: 'Alice',
  age: 30
});

// Fluent traversal
const friends = await api.nav(alice._id)
  .out('KNOWS')
  .values();
```

## Migration Checklist

- [ ] **Step 1: Schema Analysis**
  - [ ] Identify all node labels and their properties
  - [ ] Identify all relationship types and their properties
  - [ ] Identify data types for each property

- [ ] **Step 2: Schema Definition**
  - [ ] Create NODE TABLE definitions
  - [ ] Create REL TABLE definitions
  - [ ] Define PRIMARY KEYs
  - [ ] Set up indexes if needed

- [ ] **Step 3: Data Migration**
  - [ ] Export data from Neo4j
  - [ ] Transform data to CongraphDB format
  - [ ] Import nodes
  - [ ] Import relationships

- [ ] **Step 4: Code Migration**
  - [ ] Update driver imports
  - [ ] Update connection code
  - [ ] Update transaction code
  - [ ] Update result handling
  - [ ] Replace unsupported features

- [ ] **Step 5: Testing**
  - [ ] Test all queries
  - [ ] Test transactions
  - [ ] Test error handling
  - [ ] Performance testing

- [ ] **Step 6: Optimization**
  - [ ] Tune buffer pool size
  - [ ] Enable compression
  - [ ] Configure WAL checkpointing

## Common Migration Patterns

### Pattern 1: Social Network

#### Neo4j
```javascript
// Find friends of friends
const result = await session.run(`
  MATCH (me:User {id: $userId})-[:FRIEND]->(f)-[:FRIEND]->(fof)
  WHERE NOT (me)-[:FRIEND]->(fof) AND me <> fof
  RETURN fof.id, COUNT(f) AS mutualFriends
  ORDER BY mutualFriends DESC
  LIMIT 10
`, { userId });
```

#### CongraphDB (Cypher)
```javascript
const result = await conn.query(`
  MATCH (me:User {id: '${userId}'})-[:FRIEND]->(f)-[:FRIEND]->(fof)
  WHERE NOT (me)-[:FRIEND]->(fof) AND me <> fof
  RETURN fof.id, COUNT(f) AS mutualFriends
  ORDER BY mutualFriends DESC
  LIMIT 10
`);
```

#### CongraphDB (Navigator - Cleaner)
```javascript
const { CongraphDBAPI } = require('congraphdb');
const api = new CongraphDBAPI(db);

const fof = await api.nav(userId)
  .out('FRIEND')
  .out('FRIEND')
  .limit(10)
  .values();
```

### Pattern 2: Recommendation Engine

#### Neo4j
```javascript
// Collaborative filtering
const result = await session.run(`
  MATCH (u:User {id: $userId})-[:PURCHASED]->(:Product)<-[:PURCHASED]-(other:User)
  MATCH (other)-[:PURCHASED]->(rec:Product)
  WHERE NOT (u)-[:PURCHASED]->(rec)
  RETURN rec.name, COUNT(other) AS score
  ORDER BY score DESC
  LIMIT 10
`, { userId });
```

#### CongraphDB
```javascript
// Same query works with minor syntax changes
const result = await conn.query(`
  MATCH (u:User {id: '${userId}')-[:PURCHASED]->(:Product)<-[:PURCHASED]-(other:User)
  MATCH (other)-[:PURCHASED]->(rec:Product)
  WHERE NOT (u)-[:PURCHASED]->(rec)
  RETURN rec.name, COUNT(other) AS score
  ORDER BY score DESC
  LIMIT 10
`);
```

## Performance Considerations

### Differences to Note

1. **Embedded vs Client-Server**
   - CongraphDB runs in-process, no network overhead
   - Better for local-first applications
   - No connection pooling needed

2. **Schema Requirements**
   - CongraphDB requires explicit schema
   - Better performance due to known types
   - Requires upfront planning

3. **Transaction Handling**
   - Simpler transaction API in CongraphDB
   - No session management overhead
   - Direct connection usage

## Tips for Successful Migration

1. **Start with Schema**
   - Define your schema upfront based on Neo4j data
   - Use appropriate data types (STRING, INT64, DATE, etc.)

2. **Use JavaScript API for New Code**
   - Leverage CongraphDBAPI for type safety
   - Use Navigator for graph traversals
   - Keep Cypher for complex analytics

3. **Test Incrementally**
   - Migrate one query at a time
   - Verify results match Neo4j
   - Profile performance

4. **Handle Unsupported Features**
   - Replace OPTIONAL MATCH with Navigator
   - Replace FOREACH with JavaScript loops
   - Replace CALL procedures with custom logic

## See Also

- [Choosing Your Query Interface](choosing-interface.md) - Cypher vs JavaScript API vs Navigator
- [Quick Start](quick-start.md) - Getting started with CongraphDB
- [API Reference](../api/javascript-api.md) - JavaScript Native API documentation
