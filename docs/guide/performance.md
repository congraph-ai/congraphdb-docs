# Performance

CongraphDB is optimized for high-performance graph operations. This guide covers optimization strategies and best practices.

## Architecture Overview

```
┌─────────────────────────────────────┐
│         Node.js Application         │
├─────────────────────────────────────┤
│    napi-rs Bindings (lib.rs)       │
├─────────────────────────────────────┤
│         Core Engine (Rust)          │
│  ┌──────────┬──────────┬─────────┐  │
│  │ Storage  │  Query   │  Index  │  │
│  │          │ Engine   │         │  │
│  │ mmap I/O │  Cypher  │  HNSW   │  │
│  └──────────┴──────────┴─────────┘  │
└─────────────────────────────────────┘
         │              │
    .cgraph file   .wal file
```

## Key Performance Features

1. **Memory-Mapped I/O** — Files are mapped into memory for fast access
2. **Columnar Storage** — Data stored column-wise for efficient aggregations
3. **Parallel Execution** — Multi-core query processing using Rayon
4. **Native Code** — Rust implementation with no GC overhead

## Best Practices

### 1. Use Columnar Storage for Analytics

CongraphDB stores data column-wise by default, making aggregations fast:

```javascript
// Fast: Columnar aggregation
const result = await conn.query(`
  MATCH (u:User)
  RETURN AVG(u.age), MAX(u.age), MIN(u.age)
`);
```

### 2. Leverage Parallel Execution

Queries are automatically parallelized where possible:

```javascript
// This runs in parallel across CPU cores
const result = await conn.query(`
  MATCH (u:User)-[:Knows]->(f:User)
  RETURN u.name, COUNT(f) AS friend_count
`);
```

### 3. Use Appropriate Indexes

```javascript
// Create indexes for frequently filtered columns
await conn.query(`
  CREATE INDEX ON User(email)
`);

// HNSW for vector search
await conn.query(`
  CREATE HNSW INDEX ON Document(embedding, dim=128)
`);
```

### 4. Batch Operations

```javascript
// Good: Batch inserts
conn.beginTransaction();
for (let i = 0; i < 10000; i++) {
  await conn.query(`CREATE (u:User {name: 'User${i}', age: ${i}})`);
}
conn.commit();

// Avoid: Individual transactions
for (let i = 0; i < 10000; i++) {
  conn.beginTransaction();
  await conn.query(`CREATE (u:User {name: 'User${i}', age: ${i}})`);
  conn.commit();
}
```

### 5. Optimize Memory Usage

```javascript
// Adjust buffer manager size based on available memory
const db = new Database('./my-graph.cgraph', {
  bufferManagerSize: 512 * 1024 * 1024  // 512MB
});
```

## Configuration Options

### Buffer Manager Size

```javascript
const db = new Database('./my-graph.cgraph', {
  bufferManagerSize: 256 * 1024 * 1024  // 256MB (default)
});
```

**Guidelines:**
- Small datasets (< 1M nodes): 128-256 MB
- Medium datasets (1-10M nodes): 512 MB - 1 GB
- Large datasets (> 10M nodes): 2+ GB

### Compression

```javascript
const db = new Database('./my-graph.cgraph', {
  enableCompression: true  // Enable Snappy compression
});
```

Compression reduces disk usage at the cost of CPU.

### Max Database Size

```javascript
const db = new Database('./my-graph.cgraph', {
  maxDBSize: 1024 * 1024 * 1024  // 1GB limit
});
```

## Query Optimization Tips

### Use Specific Patterns

```javascript
// Good: Specific pattern
await conn.query(`
  MATCH (u:User {name: 'Alice'})-[:Knows]->(f:User)
  RETURN f.name
`);

// Avoid: Unconstrained pattern
await conn.query(`
  MATCH (u:User)-[:Knows]->(f:User)
  RETURN f.name
`);
```

### Filter Early

```javascript
// Good: Filter in WHERE clause
await conn.query(`
  MATCH (u:User)
  WHERE u.age > 25
  RETURN u.name
`);

// Avoid: Filter in RETURN
await conn.query(`
  MATCH (u:User)
  RETURN u.name
`).then(rows => rows.filter(r => r.age > 25));
```

### Use LIMIT

```javascript
// Good: Limit results
await conn.query(`
  MATCH (u:User)
  RETURN u.name
  ORDER BY u.age DESC
  LIMIT 10
`);
```

## Benchmarking

Here are some representative benchmarks (your results may vary):

| Operation | Performance |
|-----------|-------------|
| Node insertion | ~100K ops/sec |
| Relationship creation | ~80K ops/sec |
| Point lookup | ~500K ops/sec |
| Pattern matching | ~50K ops/sec |
| Vector similarity (10K vectors) | ~1K queries/sec |

## Performance Monitoring

Monitor database performance:

```javascript
const db = new Database('./my-graph.cgraph');
db.init();

// Checkpoint status
db.checkpoint();

// Storage usage
const stats = db.getStats();
console.log('Page usage:', stats.pagesUsed);
console.log('Buffer hit rate:', stats.bufferHitRate);
```

## Next Steps

- [Deployment](deployment.md) — Production deployment guide
- [Internals](internals/) — Deep dive into architecture
