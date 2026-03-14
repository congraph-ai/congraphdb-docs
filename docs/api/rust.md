# Rust API

CongraphDB is written in Rust, and you can use it directly in Rust projects.

## Documentation

The full Rust API documentation is published on [docs.rs](https://docs.rs/congraphdb/).

## Cargo.toml

Add to your `Cargo.toml`:

```toml
[dependencies]
congraphdb = "0.1"
```

## Basic Usage

```rust
use congraphdb::{Database, Connection};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Open a database
    let db = Database::new("my-graph.cgraph")?;
    db.init()?;

    // Create a connection
    let conn = db.create_connection()?;

    // Execute a query
    let result = conn.query(
        "CREATE (u:User {name: 'Alice', age: 30})"
    )?;

    // Query data
    let result = conn.query(
        "MATCH (u:User) RETURN u.name, u.age"
    )?;

    for row in result {
        println!("{:?}", row);
    }

    Ok(())
}
```

## API Reference

For the complete API reference, see:

- [docs.rs/congraphdb](https://docs.rs/congraphdb/) — Official documentation
- [GitHub Repository](https://github.com/congraph-ai/congraphdb) — Source code

## Internal Modules

- `storage` — Storage engine and data structures
- `query` — Cypher query parser and executor
- `index` — Index implementations (HNSW, hash)
- `table` — Table and schema management

## Contributing

If you're interested in contributing to CongraphDB core development, see:

- [Contributing Guide](../internals/contributing.md)
- [Architecture](../internals/architecture.md)
