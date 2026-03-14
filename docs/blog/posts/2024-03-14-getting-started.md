---
title: Getting Started with CongraphDB
date: 2024-03-14
description: A comprehensive introduction to CongraphDB for developers new to graph databases.
categories: [Tutorial]
---

# Getting Started with CongraphDB

CongraphDB is an embedded graph database for Node.js applications. In this tutorial, we'll build a simple social network to learn the basics.

## What We'll Build

A simple social network with:
- Users
- Friendships (relationships)
- Friend recommendations

## Installation

First, install CongraphDB:

```bash
npm install @congraph-ai/congraphdb
```

## Creating the Database

```javascript
const { Database } = require('@congraph-ai/congraphdb');

const db = new Database('./social-network.cgraph');
db.init();

const conn = db.createConnection();
```

## Defining the Schema

```javascript
// Create a User table
await conn.query(`
  CREATE NODE TABLE User(
    username STRING,
    display_name STRING,
    bio STRING,
    created_at INT64,
    PRIMARY KEY (username)
  )
`);

// Create a Knows relationship table
await conn.query(`
  CREATE REL TABLE Knows(FROM User TO User, since INT64)
`);
```

## Adding Users

```javascript
const users = [
  { username: 'alice', display_name: 'Alice', bio: 'Developer' },
  { username: 'bob', display_name: 'Bob', bio: 'Designer' },
  { username: 'charlie', display_name: 'Charlie', bio: 'PM' },
];

for (const user of users) {
  await conn.query(`
    CREATE (u:User {
      username: $username,
      display_name: $display_name,
      bio: $bio,
      created_at: $timestamp
    })
  `, { ...user, timestamp: Date.now() });
}
```

## Creating Friendships

```javascript
// Alice knows Bob
await conn.query(`
  MATCH (alice:User {username: 'alice'})
  MATCH (bob:User {username: 'bob'})
  CREATE (alice)-[:Knows {since: 2020}]->(bob)
`);

// Bob knows Charlie
await conn.query(`
  MATCH (bob:User {username: 'bob'})
  MATCH (charlie:User {username: 'charlie'})
  CREATE (bob)-[:Knows {since: 2021}]->(charlie)
`);
```

## Querying the Graph

### Find Alice's Friends

```javascript
const result = await conn.query(`
  MATCH (u:User {username: 'alice'})-[:Knows]->(friend)
  RETURN friend.display_name
`);

for (const row of result.getAll()) {
  console.log(row['friend.display_name']);
}
```

### Friend Recommendations

```javascript
// Friends of friends I don't know yet
const result = await conn.query(`
  MATCH (me:User {username: 'alice'})-[:Knows]->(friend)-[:Knows]->(foaf:User)
  WHERE NOT (me)-[:Knows]->(foaf) AND me <> foaf
  RETURN foaf.display_name, COUNT(friend) AS mutual_friends
  ORDER BY mutual_friends DESC
`);

console.log('Friend recommendations:');
for (const row of result.getAll()) {
  console.log(`  ${row['foaf.display_name']} (${row.mutual_friends} mutual)`);
}
```

## Cleanup

```javascript
conn.close();
db.close();
```

## Next Steps

- [Schemas Guide](../../guide/schemas.md) — More on schema design
- [Queries Guide](../../guide/queries.md) — Advanced query patterns
- [Vector Search](../../guide/vector-search.md) — Semantic search

## Full Example

```javascript
const { Database } = require('@congraph-ai/congraphdb');

async function main() {
  const db = new Database('./social-network.cgraph');
  db.init();
  const conn = db.createConnection();

  // Create schema
  await conn.query(`
    CREATE NODE TABLE User(
      username STRING,
      display_name STRING,
      bio STRING,
      PRIMARY KEY (username)
    )
  `);
  await conn.query(`
    CREATE REL TABLE Knows(FROM User TO User, since INT64)
  `);

  // Add users
  const users = [
    { username: 'alice', display_name: 'Alice', bio: 'Developer' },
    { username: 'bob', display_name: 'Bob', bio: 'Designer' },
    { username: 'charlie', display_name: 'Charlie', bio: 'PM' },
  ];

  for (const user of users) {
    await conn.query(`
      CREATE (u:User {username: $username, display_name: $display_name, bio: $bio})
    `, user);
  }

  // Add friendships
  await conn.query(`
    MATCH (alice:User {username: 'alice'})
    MATCH (bob:User {username: 'bob'})
    CREATE (alice)-[:Knows {since: 2020}]->(bob)
  `);

  // Query
  const result = await conn.query(`
    MATCH (u:User {username: 'alice'})-[:Knows]->(friend)
    RETURN friend.display_name
  `);

  console.log("Alice's friends:");
  for (const row of result.getAll()) {
    console.log(`- ${row['friend.display_name']}`);
  }

  db.close();
}

main().catch(console.error);
```

Happy graphing! :tada:
