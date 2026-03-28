# CongraphDB Documentation

> **"SQLite for Graphs"** — A high-performance, embedded graph database for Node.js built with Rust

CongraphDB is an embedded, serverless graph database designed for local-first applications. Built with Rust for memory safety and extreme performance, it provides a native Node.js bindings layer via napi-rs.

## What's New in v0.1.6

- **Dual Query Interface** — Choose between Cypher Query Language OR JavaScript-Native API
  - **Cypher**: Industry-standard graph query language for complex operations
  - **JavaScript API**: Native methods with fluent Navigator API for simple CRUD
  - **CongraphDBAPI class** — Complete NodeAPI, EdgeAPI, Pattern matching, and Navigator
  - **TypeScript definitions** — Full type coverage for all API classes
- **Complete DML Operations** — CREATE, SET, DELETE, REMOVE, MERGE with ON MATCH/ON CREATE
- **Query Statistics** — Track execution time, row count, and query type
- **Dynamic Properties** — Auto-create columns when setting non-existent properties
- **Property Filters** — Property filters in MATCH patterns now work correctly
- **CASE Expressions** — Full conditional logic support in queries

See the [Changelog](releases/changelog.md) for full release notes.

## Quick Start

```bash
npm install congraphdb
```

```javascript
const { Database } = require('congraphdb');

// Create or open a database
const db = new Database('./my-graph.cgraph');
db.init();

// Create a connection
const conn = db.createConnection();

// Define schema
await conn.query(`
  CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))
`);

await conn.query(`
  CREATE REL TABLE Knows(FROM User TO User, since INT64)
`);

// Insert data
await conn.query(`
  CREATE (alice:User {name: 'Alice', age: 30})
         -[:Knows {since: 2020}]->
         (bob:User {name: 'Bob', age: 25})
`);

// Query
const result = await conn.query(`
  MATCH (u:User)-[k:Knows]->(f:User)
  WHERE u.name = 'Alice'
  RETURN u.name, k.since, f.name
`);

// Get all results
const rows = result.getAll();
for (const row of rows) {
  console.log(row);
}

db.close();
```

## Features

- :rocket: **Embedded & Serverless** — No separate database process. Store data locally in a single `.cgraph` file.
- :zap: **High Performance** — Rust-powered with memory-mapped I/O, columnar storage, and vectorized execution.
- :mag: **Cypher Query Language** — Support for Cypher graph query syntax.
- :robot: **AI-Ready** — Built-in HNSW index for vector similarity search on embeddings.
- :package: **Easy Distribution** — Prebuilt binaries for Windows, macOS, and Linux via npm.
- :moneybag: **ACID Transactions** — Serializable transactions with write-ahead logging.
- :lock: **Memory Safe** — Built with Rust — no segfaults, no memory leaks.

## Resources

- **[Installation Guide](guide/installation.md)** — Get started with CongraphDB
- **[Quick Start](guide/quick-start.md)** — Learn the basics
- **[Sample Project](https://github.com/congraph-ai/congraphdb-sample)** — Working examples and code samples
- **[API Reference](api/index.md)** — Complete API documentation
- **[GitHub Repository](https://github.com/congraph-ai/congraphdb)** — Source code

## Status

CongraphDB is currently in **alpha** development (v0.1.6). The core storage engine, transaction system, and a robust Cypher/JavaScript query interface are implemented, with features like path finding, vector search, and DML operations fully supported.

## License

MIT License — see [LICENSE](https://github.com/congraph-ai/congraphdb/blob/main/LICENSE) file for details.
