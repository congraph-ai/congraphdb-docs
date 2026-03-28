# CongraphDB Documentation

> **"SQLite for Graphs"** — A high-performance, embedded graph database for Node.js built with Rust

CongraphDB is an embedded, serverless graph database designed for local-first applications. Built with Rust for memory safety and extreme performance, it provides a native Node.js bindings layer via napi-rs.

## What's New in v0.1.7

- **Query Result Modifiers** — ORDER BY with ASC/DESC, SKIP, and LIMIT clauses for result control
- **Variable-Length Path Traversal** — `[*..n]` syntax for flexible path patterns
- **Union Operator** — Combine results from multiple MATCH patterns
- **Comprehensive TypeScript Definitions** — Complete index.d.ts for CongraphDB API
- **Major Codebase Refactoring** — Improved modular structure (query binder, operators, N-API bindings)
- **Bug Fixes** — Relationship RETURN, multi-node-table patterns, case-insensitive keywords, edge query compatibility

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

CongraphDB is currently in **alpha** development (v0.1.7). The core storage engine, transaction system, and a robust Cypher/JavaScript query interface are implemented, with features like path finding, vector search, DML operations, and query result modifiers fully supported.

## License

MIT License — see [LICENSE](https://github.com/congraph-ai/congraphdb/blob/main/LICENSE) file for details.
