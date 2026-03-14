# Index Structures

CongraphDB uses several index structures for efficient data access.

## Index Types

| Index Type | Use Case | Complexity |
|------------|----------|------------|
| HNSW | Vector similarity search | O(log n) |
| Hash | Exact match lookups | O(1) |
| Primary Key | Built-in for PK columns | O(1) |

## HNSW Index

Hierarchical Navigable Small World (HNSW) is used for vector similarity search.

### What is HNSW?

HNSW is a graph-based index for approximate nearest neighbor search:

```
Layer 2:  1 ───────────────> 2
          │                   │
          ↓                   ↓
Layer 1:  1 ──> 3 ──> 4 ──> 2
          │     │     │
          ↓     ↓     ↓
Layer 0:  1 ──> 3 ──> 5 ──> 4 ──> 2 ──> 6
```

### Properties

| Property | Value |
|----------|-------|
| Build Time | O(n log n) |
| Search Time | O(log n) |
| Memory | O(n × M) |
| Accuracy | Configurable (ef) |

### Parameters

```javascript
CREATE HNSW INDEX ON Document(embedding, dim=128, M=16)
```

| Parameter | Description | Default | Effect |
|-----------|-------------|---------|--------|
| `dim` | Vector dimension | - | Must match column |
| `M` | Max connections per node | 16 | Higher = more accurate, slower, more memory |
| `ef_construction` | Build-time candidates | 100 | Higher = better quality, slower build |
| `ef_runtime` | Search-time candidates | 10 | Higher = more accurate, slower search |

### Search Algorithm

```
search_hnsw(query, k):
  // Start at random point in top layer
  current = random_point()
  layer = max_layer

  // Greedy search down layers
  while layer >= 0:
    current = greedy_search_layer(query, current, layer)
    layer -= 1

  // Refine in bottom layer
  candidates = beam_search(query, current, ef_runtime)
  return top_k(candidates, k)
```

### Example Usage

```javascript
// Create HNSW index
await conn.query(`
  CREATE HNSW INDEX ON Document(embedding, dim=384, M=16)
`);

// Search with index
const result = await conn.query(`
  MATCH (d:Document)
  RETURN d.title, d.embedding <-> $query AS distance
  ORDER BY distance
  LIMIT 5
`, { query: embeddingVector });
```

### When to Use HNSW

- Vector similarity search
- Recommendation systems
- Semantic search
- Approximate nearest neighbor queries

## Hash Index

Hash indexes provide O(1) exact match lookups.

### Structure

```
┌─────────────────────────────────────────────────┐
│               Hash Index                        │
├─────────────────────────────────────────────────┤
│  "alice" → [row_id_1, row_id_5, ...]           │
│  "bob"   → [row_id_2, row_id_7, ...]           │
│  "charlie" → [row_id_3, ...]                   │
└─────────────────────────────────────────────────┘
```

### Creating Hash Indexes

```javascript
CREATE INDEX ON User(email)
CREATE INDEX ON User(username)
```

### Query Optimization

```cypher
-- Without index: Full table scan
MATCH (u:User) WHERE u.email = 'alice@example.com'

-- With index: Direct lookup
MATCH (u:User) WHERE u.email = 'alice@example.com'
```

### When to Use Hash Index

- Exact match lookups
- IN clauses
- Unique constraints
- Foreign key lookups

## Primary Key Index

Every node table has a built-in primary key index.

```javascript
CREATE NODE TABLE User(
  username STRING,
  PRIMARY KEY (username)  // Auto-indexed
)
```

### Benefits

- O(1) lookups by primary key
- Automatic uniqueness constraint
- Used internally for relationships

## Index Statistics

Query index statistics:

```javascript
// Check index usage (planned)
const stats = await conn.query(`
  EXPLAIN MATCH (u:User {email: 'alice@example.com'}) RETURN u
`);
console.log(stats.indexUsed);  // true or false
```

## Index Maintenance

### Rebuilding Indexes

```javascript
// Rebuild an index (planned feature)
REBUILD INDEX User_email
```

### Dropping Indexes

```javascript
// Drop an index
DROP INDEX User_email
```

## Performance Comparison

| Operation | No Index | Hash Index | HNSW Index |
|-----------|----------|------------|------------|
| Exact match | O(n) | O(1) | N/A |
| Range query | O(n) | N/A | N/A |
| Vector search | O(n) | N/A | O(log n) |
| Insert | O(1) | O(1) | O(log n) |

## Future Index Types

Planned for future releases:

- **B-tree** — Range queries, ordering
- **Full-text** — Text search
- **GIS** — Geospatial queries
- **Bitmap** — Low-cardinality columns

## See Also

- [Vector Search](../guide/vector-search.md) — Using HNSW
- [Query Execution](query-execution.md) — How queries use indexes
- [Performance](../guide/performance.md) — Optimization tips
