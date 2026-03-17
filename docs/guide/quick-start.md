# Quick Start

This guide will help you get started with CongraphDB in just a few minutes.

CongraphDB supports **two query interfaces**:

1. **Cypher Query Language** - Industry-standard graph query language (recommended for complex queries)
2. **JavaScript Native API** - Programmatic interface (recommended for simple CRUD)

Choose the approach that best fits your use case. See [Choosing Your Query Interface](choosing-interface.md) for more details.

---

## Option A: Cypher Query Language

### Step 1: Install CongraphDB

```bash
npm install @congraph-ai/congraphdb
```

## Step 2: Create a Database

```javascript
const { Database } = require('@congraph-ai/congraphdb');

// Create or open a database
const db = new Database('./my-graph.cgraph');
db.init();
```

## Step 3: Define a Schema

```javascript
const conn = db.createConnection();

// Create a node table
await conn.query(`
  CREATE NODE TABLE User(
    name STRING,
    age INT64,
    email STRING,
    PRIMARY KEY (name)
  )
`);

// Create a relationship table
await conn.query(`
  CREATE REL TABLE Knows(FROM User TO User, since INT64)
`);
```

## Step 4: Insert Data

```javascript
// Create users
await conn.query(`
  CREATE (alice:User {name: 'Alice', age: 30, email: 'alice@example.com'})
`);
await conn.query(`
  CREATE (bob:User {name: 'Bob', age: 25, email: 'bob@example.com'})
`);

// Create a relationship
await conn.query(`
  MATCH (alice:User {name: 'Alice'})
  MATCH (bob:User {name: 'Bob'})
  CREATE (alice)-[:Knows {since: 2020}]->(bob)
`);
```

## Step 5: Query Data

```javascript
const result = await conn.query(`
  MATCH (u:User)-[k:Knows]->(f:User)
  WHERE u.name = 'Alice'
  RETURN u.name AS user, f.name AS friend, k.since AS since
`);

const rows = result.getAll();
console.log(rows);
// Output: [{ user: 'Alice', friend: 'Bob', since: 2020 }]
```

## Step 6: Clean Up

```javascript
result.close();
conn.close();
db.close();
```

## Complete Example (Cypher)

```javascript
const { Database } = require('@congraph-ai/congraphdb');

async function main() {
  const db = new Database('./my-graph.cgraph');
  db.init();

  const conn = db.createConnection();

  // Create schema
  await conn.query(`
    CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))
  `);
  await conn.query(`
    CREATE REL TABLE Knows(FROM User TO User, since INT64)
  `);

  // Insert data
  await conn.query(`
    CREATE (alice:User {name: 'Alice', age: 30})
  `);
  await conn.query(`
    CREATE (bob:User {name: 'Bob', age: 25})
  `);
  await conn.query(`
    MATCH (a:User {name: 'Alice'})
    MATCH (b:User {name: 'Bob'})
    CREATE (a)-[:Knows {since: 2020}]->(b)
  `);

  // Query
  const result = await conn.query(`
    MATCH (u:User)-[k:Knows]->(f:User)
    RETURN u.name, k.since, f.name
  `);

  console.log(result.getAll());

  db.close();
}

main().catch(console.error);
```

---

## Option B: JavaScript Native API

The JavaScript Native API provides a programmatic alternative to Cypher, ideal for simple CRUD operations and type safety.

### Step 1: Install CongraphDB

```bash
npm install @congraph-ai/congraphdb
```

### Step 2: Create a Database

```javascript
const { Database, CongraphDBAPI } = require('@congraph-ai/congraphdb');

// Create or open a database
const db = new Database('./my-graph.cgraph');
await db.init();

// Initialize the JavaScript API
const api = new CongraphDBAPI(db);
```

### Step 3: Define a Schema

```javascript
const conn = db.createConnection();

// Create node and relationship tables (still uses Cypher for DDL)
await conn.query(`
  CREATE NODE TABLE User(
    name STRING,
    age INT64,
    email STRING,
    PRIMARY KEY (name)
  )
`);

await conn.query(`
  CREATE REL TABLE Knows(FROM User TO User, since INT64)
`);
```

### Step 4: Insert Data

```javascript
// Create users
const alice = await api.createNode('User', {
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
});

const bob = await api.createNode('User', {
  name: 'Bob',
  age: 25,
  email: 'bob@example.com'
});

// Create a relationship
await api.createEdge(alice._id, 'Knows', bob._id, {
  since: 2020
});
```

### Step 5: Query Data

```javascript
// Find Alice's friends using pattern matching
const friends = await api.find({
  subject: alice._id,
  predicate: 'Knows',
  object: api.v('friend')
});

console.log(friends);
// Output: [{ friend: { name: 'Bob', age: 25, ... } }]

// Or use the Navigator for fluent traversal
const friendNames = await api.nav(alice._id)
  .out('Knows')
  .values();

console.log(friendNames);
// Output: [{ name: 'Bob', age: 25, ... }]
```

### Step 6: Clean Up

```javascript
await api.close();
await db.close();
```

### Complete Example (JavaScript API)

```javascript
const { Database, CongraphDBAPI } = require('@congraph-ai/congraphdb');

async function main() {
  const db = new Database('./my-graph.cgraph');
  await db.init();

  const api = new CongraphDBAPI(db);
  const conn = db.createConnection();

  // Create schema
  await conn.query(`
    CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))
  `);
  await conn.query(`
    CREATE REL TABLE Knows(FROM User TO User, since INT64)
  `);

  // Insert data
  const alice = await api.createNode('User', {
    name: 'Alice',
    age: 30
  });

  const bob = await api.createNode('User', {
    name: 'Bob',
    age: 25
  });

  await api.createEdge(alice._id, 'Knows', bob._id, { since: 2020 });

  // Query with pattern matching
  const friends = await api.find({
    subject: alice._id,
    predicate: 'Knows',
    object: api.v('friend')
  });

  console.log('Friends:', friends);

  // Query with Navigator
  const friendNames = await api.nav(alice._id)
    .out('Knows')
    .values();

  console.log('Friend names:', friendNames.map(f => f.name));

  await api.close();
  await db.close();
}

main().catch(console.error);
```

---

## Which Should You Choose?

| Use Case | Recommended Interface |
|----------|---------------------|
| Simple CRUD operations | JavaScript API |
| Complex graph queries | Cypher |
| Multi-hop traversal | Navigator (part of JavaScript API) |
| Type safety/TypeScript | JavaScript API |
| Migrating from Neo4j | Cypher |
| Migrating from LevelGraph | Navigator |

For more details, see [Choosing Your Query Interface](choosing-interface.md).

## Next Steps

- [Schemas](schemas.md) — Learn more about defining schemas
- [Queries](queries.md) — Explore Cypher query syntax
- [Transactions](transactions.md) — Work with transactions
