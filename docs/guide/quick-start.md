# Quick Start

This guide will help you get started with CongraphDB in just a few minutes.

## Step 1: Install CongraphDB

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

## Complete Example

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

## Next Steps

- [Schemas](schemas.md) — Learn more about defining schemas
- [Queries](queries.md) — Explore Cypher query syntax
- [Transactions](transactions.md) — Work with transactions
