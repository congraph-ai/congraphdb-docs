# Query Execution

How CongraphDB processes Cypher queries from parsing to execution.

## Query Processing Pipeline

```
Cypher Query String
        │
        ▼
    ┌──────────┐
    │  Parser  │  →  AST (Abstract Syntax Tree)
    │ (cypher) │     using nom combinator
    └──────────┘
        │
        ▼
  ┌─────────────┐
  │  Binder     │  →  Bound Query
  │ (semantic) │     - Validates labels/properties
  └─────────────┘     - Binds variables to tables
        │
        ▼
 ┌────────────────┐
  │  Builder      │  →  Physical Operator Tree
  │ (executor)    │     - Constructs execution plan
  └────────────────┘
        │
        ▼
  ┌──────────────┐
  │   Executor   │  →  Results
  │ (execution)  │     - Streaming execution
  └──────────────┘
```

## 1. Parsing

The parser converts Cypher text into an AST using the `nom` combinator library.

### Parser Structure

Located in `src/query/cypher/`:

- `mod.rs` - Main parser module
- `clause.rs` - Clause parsing (MATCH, RETURN, WHERE, etc.)
- `expr.rs` - Expression parsing
- `pattern.rs` - Pattern parsing for graph patterns
- `schema.rs` - Schema statement parsing (CREATE NODE TABLE, etc.)
- `types.rs` - AST type definitions

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

## 2. Binding (Semantic Analysis)

The binder performs semantic analysis on the AST, validating references and binding variables to specific tables.

### Binder Structure

Located in `src/query/binder/`:

- `binder.rs` - Main binder implementation
- `clause.rs` - Clause-level binding
- `statement.rs` - Statement-level binding
- `expression.rs` - Expression binding and validation
- `pattern.rs` - Pattern binding (nodes, relationships)
- `types.rs` - Bound query types

### Binding Process

1. **Validate Labels**: Check that all referenced labels exist in the catalog
2. **Validate Properties**: Check that property references are valid for their types
3. **Bind Variables**: Map variables to specific table sources
4. **Type Checking**: Ensure expressions are type-safe
5. **Resolve Scopes**: Handle variable scoping across query clauses

### Example Binding

For the query above, binding produces:

```
BoundQuery {
  bound_clauses: [
    BoundMatch {
      bound_pattern: [
        BoundNode {
          variable: "u",
          table: "User",
          filters: [PropertyFilter("name", Equals, "Alice")]
        },
        BoundRelationship {
          type: "KNOWS",
          direction: Outgoing,
          table: "KNOWS"
        },
        BoundNode {
          variable: "f",
          table: "User",
          filters: []
        }
      ]
    },
    BoundReturn {
      items: [
        BoundProperty("u", "name", StringColumn),
        BoundProperty("f", "name", StringColumn)
      ]
    }
  ]
}
```

## 3. Building (Physical Planning)

The builder converts the bound query into a physical operator tree optimized for execution.

### Builder Structure

Located in `src/query/executor/builder.rs`:

- Converts bound clauses to operators
- Handles operator composition
- Manages variable scope across operators

### Physical Operators

Operators are organized into three categories in `src/query/operator/`:

#### Streaming Operators (`streaming/`)

| Operator | Description | File |
|----------|-------------|------|
| `Scan` | Full table scan | `scan.rs` |
| `PatternMatch` | Graph pattern matching | `pattern_match.rs` |
| `OptionalMatch` | Optional pattern matching (LEFT JOIN) | `optional_match.rs` |
| `Transform` | Column projection and transformation | `transform.rs` |

#### Non-Streaming Operators (`non_streaming/`)

| Operator | Description | File |
|----------|-------------|------|
| `Aggregate` | Aggregation (COUNT, SUM, AVG, etc.) | `aggregate.rs` |
| `Path` | Path finding operations | `path.rs` |
| `PathVarLength` | Variable-length path patterns | `path_var_length.rs` |

#### Write Operators (`write/`)

| Operator | Description | File |
|----------|-------------|------|
| `Create` | CREATE clause execution | `create.rs` |
| `Merge` | MERGE clause execution | `merge.rs` |
| `Delete` | DELETE clause execution | `delete.rs` |
| `Update` | SET clause execution | `update.rs` |

### Example Physical Plan

```
Transform(u.name, f.name)
  └─ PatternMatch
      ├─ Scan(User) u
      │  └─ Filter(u.name = 'Alice')
      └─ Scan(Knows) -> Scan(User) f
```

## 4. Execution

The executor runs the physical operator tree using a streaming execution model.

### Executor Structure

Located in `src/query/executor/`:

- `execution.rs` - Main execution engine
- `result.rs` - Result handling and streaming
- `stats.rs` - Execution statistics
- `table_manager.rs` - Table access during execution
- `utils.rs` - Execution utilities

### Streaming Execution

CongraphDB uses a streaming execution model (Volcano-style):

```
┌─────────────────────────────────────────────────┐
│              Operator Pipeline                  │
├─────────────────────────────────────────────────┤
│  Transform pulls from PatternMatch              │
│    PatternMatch pulls from Scan                 │
│      Scan reads from storage                    │
│    PatternMatch joins results                   │
│  Transform projects final columns               │
└─────────────────────────────────────────────────┘
```

### Pull-Based Iteration

```rust
// Simplified execution model
while let Some(row) = operator.next() {
    // Process row
    // Return to client
}
```

### Result Streaming

Results are streamed to the client to minimize memory usage:

1. **Row by row**: Each row is produced and sent immediately
2. **No materialization**: Intermediate results are not stored
3. **Lazy evaluation**: Operators only compute when needed

## Query Modifiers

### LIMIT and SKIP

- **LIMIT**: Stops execution after N rows
- **SKIP**: Skips first N rows
- **Optimization**: Applied at the executor level

### ORDER BY

- **Sorting**: Uses external sort for large result sets
- **Optimization**: Pushed down when possible

### DISTINCT

- **Deduplication**: Uses hashing for efficient duplicate removal
- **Optimization**: Combined with aggregation when possible

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

## Write Query Execution

Write queries (CREATE, MERGE, DELETE, SET) use special write operators:

```
CREATE (u:User {name: 'Alice'})

Execution:
  1. Parse and bind
  2. Build operator tree with Create operator
  3. Execute Create operator:
     - Allocate new node ID
     - Write to WAL
     - Update in-memory structures
  4. Return created node
```

## Error Handling

Errors can occur at any stage:

| Stage | Error Type | Example |
|-------|------------|---------|
| Parser | SyntaxError | Invalid Cypher syntax |
| Binder | SemanticError | Undefined label, type mismatch |
| Builder | PlanError | Invalid query structure |
| Executor | RuntimeError | I/O error, constraint violation |

## Performance Considerations

### Memory Usage

- **Streaming**: Results streamed to avoid large allocations
- **No intermediate materialization**: Operators pass rows directly
- **Efficient representations**: Compact data structures

### I/O Optimization

- **Prefetching**: Sequential read ahead
- **Batching**: Group page reads
- **Caching**: Keep hot pages in buffer pool

### CPU Optimization

- **Zero-copy**: Avoid unnecessary data copying
- **Cache locality**: Columnar storage improves cache hits
- **Branch prediction**: Minimize branches in hot paths

## See Also

- [Architecture](architecture.md) — System overview
- [Binder Details](binder.md) — Semantic analysis and binding
- [Operators](operators.md) — Physical operator reference
- [Storage Format](storage-format.md) — On-disk structure
- [Index Structures](index-structures.md) — HNSW details
