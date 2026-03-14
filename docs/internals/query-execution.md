# Query Execution

How CongraphDB processes Cypher queries from parsing to execution.

## Query Processing Pipeline

```
Cypher Query String
        │
        ▼
    ┌──────────┐
    │  Parser  │  →  AST (Abstract Syntax Tree)
    └──────────┘
        │
        ▼
  ┌─────────────┐
  │  Planner    │  →  Logical Plan
  └─────────────┘
        │
        ▼
 ┌────────────────┐
  │   Optimizer   │  →  Optimized Physical Plan
  └────────────────┘
        │
        ▼
  ┌──────────────┐
  │   Executor   │  →  Results (Parallel)
  └──────────────┘
```

## 1. Parsing

The parser converts Cypher text into an AST using the `nom` combinator library.

### Example

Input:
```cypher
MATCH (u:User {name: 'Alice'})-[:KNOWS]->(f:User)
RETURN u.name, f.name
```

AST:
```
Query {
  clauses: [
    Match {
      pattern: Pattern {
        parts: [
          Node {
            variable: "u",
            label: "User",
            predicates: [Equals("name", "Alice")]
          },
          Relationship {
            type: "KNOWS",
            direction: Outgoing
          },
          Node {
            variable: "f",
            label: "User"
          }
        ]
      }
    },
    Return {
      items: [
        Property("u", "name"),
        Property("f", "name")
      ]
    }
  ]
}
```

## 2. Logical Planning

The planner converts the AST into a logical query plan.

### Logical Operators

| Operator | Description |
|----------|-------------|
| `Scan` | Full table scan |
| `Filter` | Predicate filtering |
| `Project` | Column selection |
| `HashJoin` | Hash-based join |
| `NestedLoopJoin` | Nested loop join |
| `Aggregate` | Aggregation |
| `Sort` | Ordering |
| `Limit` | Result limiting |
| `Distinct` | Duplicate removal |

### Example Logical Plan

```
Project(u.name, f.name)
  └─ NestedLoopJoin
      ├─ Scan(User) u
      │  └─ Filter(u.name = 'Alice')
      └─ Scan(Knows) -> Scan(User) f
```

## 3. Optimization

The optimizer rewrites the plan for better performance.

### Optimization Rules

1. **Predicate Pushdown**
   ```
   Before: Scan → Filter
   After:  FilteredScan

   Scan all users, then filter by age > 25
   → Scan users with age > 25 directly
   ```

2. **Projection Pushdown**
   ```
   Before: Scan(all columns) → Project
   After:  Scan(only needed columns)

   Scan all columns, then select name
   → Scan only name column
   ```

3. **Join Reordering**
   ```
   Before: (A × B) × C  (large joins)
   After:  A × (B × C)  (small joins first)
   ```

4. **Index Selection**
   ```
   Before: Full scan with filter
   After:  Index lookup

   Scan(User) WHERE name = 'Alice'
   → IndexLookup(User.name = 'Alice')
   ```

## 4. Physical Planning

The logical plan is converted to physical operators with specific algorithms.

### Physical Operators

| Logical | Physical | Description |
|---------|----------|-------------|
| Scan | ColumnScan | Read column pages |
| Filter | SIMDFilter | Vectorized filtering |
| HashJoin | ParallelHashJoin | Multi-threaded hash join |
| Aggregate | ParallelAggregate | Multi-threaded aggregation |
| Sort | ExternalSort | Spill-to-disk sorting |

## 5. Execution

The executor runs the physical plan using parallel execution via `rayon`.

### Parallel Execution Strategy

```
┌─────────────────────────────────────────────────┐
│                 Query Execution                 │
├─────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐         │
│  │Thread 1 │  │Thread 2 │  │Thread N │         │
│  │ Chunk 1 │  │ Chunk 2 │  │ Chunk N │         │
│  └─────────┘  └─────────┘  └─────────┘         │
│        │            │            │              │
│        └────────────┴────────────┘              │
│                     │                           │
│              ┌──────────┐                       │
│              │  Merge   │                       │
│              └──────────┘                       │
└─────────────────────────────────────────────────┘
```

### Work Distribution

1. **Chunking:** Data divided into chunks (e.g., 1000 rows each)
2. **Stealing:** Work stealing for load balancing
3. **Merging:** Partial results merged at end

### Example: Parallel Aggregation

```
Query: MATCH (u:User) RETURN AVG(u.age)

Execution:
  Thread 1: AVG([25, 30, 28]) → 27.7  (count: 3)
  Thread 2: AVG([35, 40, 32]) → 35.7  (count: 3)
  Thread 3: AVG([22, 27, 29]) → 26.0  (count: 3)

  Final: (27.7×3 + 35.7×3 + 26.0×3) / 9 = 29.8
```

## Vector Query Execution

Vector similarity queries use HNSW for approximate nearest neighbor search:

```
Query: ORDER BY embedding <-> $query

Execution:
  1. Convert query to vector
  2. Traverse HNSW graph to find nearest candidates
  3. Compute exact distances for candidates
  4. Sort by distance
  5. Apply LIMIT
```

### HNSW Search

```
┌─────────────────────────────────────────────────┐
│  HNSW Graph Traversal                          │
├─────────────────────────────────────────────────┤
│  1. Enter at random point                       │
│  2. Greedy search through layers                │
│  3. Refine in bottom layer                      │
│  4. Return top-k results                        │
└─────────────────────────────────────────────────┘
```

## Performance Considerations

### Memory Usage

- **Streaming:** Results streamed to avoid large allocations
- **Copy-on-write:** Shared data where possible
- **Arena allocation:** Bump pointer for temporary data

### I/O Optimization

- **Prefetching:** Sequential read ahead
- **Batching:** Group page reads
- **Caching:** Keep hot pages in buffer pool

### CPU Optimization

- **SIMD:** Vectorized operations where applicable
- **Cache locality:** Columnar storage improves cache hits
- **Branch prediction:** Minimize branches in hot paths

## See Also

- [Architecture](architecture.md) — System overview
- [Storage Format](storage-format.md) — On-disk structure
- [Index Structures](index-structures.md) — HNSW details
