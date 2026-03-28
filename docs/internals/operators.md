# Physical Operators

Reference documentation for all physical operators in CongraphDB's query execution engine.

## Operator Overview

Operators are organized into three categories based on their execution characteristics:

- **Streaming Operators**: Process rows one at a time, producing output immediately
- **Non-Streaming Operators**: Require seeing all input before producing output
- **Write Operators**: Modify database state

## Operator Module Structure

```
src/query/operator/
├── mod.rs              # Module exports
├── core/               # Core operator traits and types
│   ├── mod.rs
│   ├── base.rs         # Operator trait definitions
│   └── types.rs        # Operator types
├── streaming/          # Streaming operators
│   ├── mod.rs
│   ├── scan.rs
│   ├── pattern_match.rs
│   ├── optional_match.rs
│   └── transform.rs
├── non_streaming/      # Non-streaming operators
│   ├── mod.rs
│   ├── aggregate.rs
│   ├── path.rs
│   └── path_var_length.rs
└── write/              # Write operators
    ├── mod.rs
    ├── create.rs
    ├── merge.rs
    ├── delete.rs
    └── update.rs
```

## Streaming Operators

Streaming operators implement the pull-based iterator model, producing one row at a time.

### Scan Operator

**File**: `streaming/scan.rs`

Performs a full table scan on a node table.

```cypher
MATCH (u:User)
RETURN u
```

**Behavior**:
- Reads all rows from the specified table
- Applies optional filters during scan
- Produces rows sequentially

**Complexity**: O(n) where n is the number of rows

### PatternMatch Operator

**File**: `streaming/pattern_match.rs`

Executes graph pattern matching for MATCH clauses.

```cypher
MATCH (u:User)-[:KNOWS]->(f:User)
RETURN u.name, f.name
```

**Behavior**:
- Starts from one or more seed nodes
- Traverses relationships to find matching patterns
- Applies filters at each step
- Produces matching result rows

**Complexity**: O(V + E) where V is vertices, E is edges

**Optimizations**:
- Index lookups for seed nodes
- Filter pushdown
- Join ordering

### OptionalMatch Operator

**File**: `streaming/optional_match.rs`

Implements optional pattern matching (LEFT JOIN semantics).

```cypher
MATCH (u:User)
OPTIONAL MATCH (u)-[:WORKS_AT]->(c:Company)
RETURN u.name, c.name
```

**Behavior**:
- Produces rows even when no match is found
- Fills unmatched variables with null
- Preserves all rows from the left side

**Complexity**: O(V + E)

### Transform Operator

**File**: `streaming/transform.rs`

Implements projection, renaming, and expression evaluation.

```cypher
MATCH (u:User)
RETURN u.name AS username, u.age * 2 AS double_age
```

**Behavior**:
- Evaluates expressions for each input row
- Renames columns as specified
- Projects only required columns

**Complexity**: O(n) where n is input rows

## Non-Streaming Operators

Non-streaming operators require accumulating all input before producing output.

### Aggregate Operator

**File**: `non_streaming/aggregate.rs`

Implements aggregation functions (COUNT, SUM, AVG, MIN, MAX).

```cypher
MATCH (u:User)
RETURN COUNT(*) AS total, AVG(u.age) AS avg_age
```

**Behavior**:
- Accumulates aggregation state across all rows
- Handles GROUP BY for grouped aggregation
- Produces one row per group

**Supported Aggregations**:
- `COUNT(*)` - Count all rows
- `COUNT(expr)` - Count non-null values
- `SUM(expr)` - Sum of numeric values
- `AVG(expr)` - Average of numeric values
- `MIN(expr)` - Minimum value
- `MAX(expr)` - Maximum value

**Complexity**: O(n) where n is input rows

### Path Operator

**File**: `non_streaming/path.rs`

Finds paths between nodes in the graph.

```cypher
MATCH path = (a:User)-[:KNOWS*]->(b:User)
WHERE a.name = 'Alice' AND b.name = 'Bob'
RETURN path
```

**Behavior**:
- Performs graph traversal to find paths
- Supports variable-length relationships
- Returns path objects with nodes and relationships

**Complexity**: O((V+E) × path_length)

### PathVarLength Operator

**File**: `non_streaming/path_var_length.rs`

Optimized operator for variable-length relationship traversal.

```cypher
MATCH (a:User)-[:KNOWS*1..3]->(b:User)
RETURN a.name, b.name
```

**Behavior**:
- Efficiently traverses relationships of variable length
- Supports minimum and maximum length bounds
- Prunes paths that exceed maximum length

**Complexity**: O((V+E) × max_length)

## Write Operators

Write operators modify database state and are transactional.

### Create Operator

**File**: `write/create.rs`

Implements the CREATE clause.

```cypher
CREATE (u:User {name: 'Alice', age: 30})
```

**Behavior**:
- Allocates new node ID
- Validates properties against schema
- Writes to WAL
- Updates in-memory structures
- Returns created node

**Complexity**: O(1)

### Merge Operator

**File**: `write/merge.rs`

Implements the MERGE clause (create if not exists).

```cypher
MERGE (u:User {name: 'Alice'})
ON CREATE SET u.created_at = timestamp()
ON MATCH SET u.last_seen = timestamp()
```

**Behavior**:
- First attempts to find matching node
- If found: executes ON MATCH actions
- If not found: creates node and executes ON CREATE actions
- Atomic operation within transaction

**Complexity**: O(1) for indexed lookups, O(n) for scan

### Delete Operator

**File**: `write/delete.rs`

Implements the DELETE clause.

```cypher
MATCH (u:User)
WHERE u.name = 'Alice'
DELETE u
```

**Behavior**:
- Validates node can be deleted (no existing relationships)
- Removes node from table
- Writes to WAL
- Updates in-memory structures

**Complexity**: O(1)

### Update Operator

**File**: `write/update.rs`

Implements the SET clause.

```cypher
MATCH (u:User {name: 'Alice'})
SET u.age = 31, u.updated_at = timestamp()
```

**Behavior**:
- Validates property types
- Updates property values
- Handles special cases (labels, properties)
- Writes to WAL

**Complexity**: O(1)

## Operator Composition

Operators are composed into execution trees:

```cypher
MATCH (u:User)-[:KNOWS]->(f:User)
WHERE u.age > 25
RETURN u.name, f.name
ORDER BY u.name
LIMIT 10
```

Operator tree:
```
Limit(10)
  └─ Sort(u.name)
      └─ Transform(u.name, f.name)
          └─ PatternMatch
              ├─ Scan(User) u
              │  └─ Filter(u.age > 25)
              └─ Scan(KNOWS) -> Scan(User) f
```

## Operator Execution Model

### Pull-Based Iteration

All operators implement the pull-based iterator pattern:

```rust
trait Operator {
    fn next(&mut self) -> Option<&Row>;
    fn close(&mut self);
}
```

### Execution Flow

```
Executor asks top operator for row
  ↓
Top operator asks child for row
  ↓
Child operator asks its child for row
  ↓
...
  ↓
Leaf operator (Scan) produces row
  ↓
Row bubbles up through operator chain
  ↓
Each operator transforms/passes row
  ↓
Executor receives final row
  ↓
Row sent to client
```

## Memory Management

### Streaming Operators

- **Memory**: O(1) per operator
- **Benefit**: Can process unlimited data

### Non-Streaming Operators

- **Memory**: O(n) for aggregation
- **Benefit**: Single pass through data

### Write Operators

- **Memory**: O(1) per operation
- **Benefit**: Constant memory, transactional

## Optimization Opportunities

### Predicate Pushdown

Push filters to scan level:

```
Before: Scan → Filter
After:  FilteredScan
```

### Projection Pruning

Only read needed columns:

```
Before: Scan(all columns) → Project
After:  Scan(only needed columns)
```

### Early Termination

Stop execution when LIMIT is reached:

```
Scan → ... → Limit(10)
Stop after producing 10 rows
```

## See Also

- [Query Execution](query-execution.md) — How operators are used
- [Architecture](architecture.md) — System design
- [Binder](binder.md) — How queries are bound
