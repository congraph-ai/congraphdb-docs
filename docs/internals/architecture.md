# Architecture

CongraphDB is built with a layered architecture for performance and maintainability.

## System Overview

```
┌─────────────────────────────────────────────┐
│           Node.js Application              │
│  (Business logic, API endpoints, etc.)      │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│         napi-rs Bindings Layer             │
│  (lib.rs - TypeScript ↔ Rust bridge)       │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Query Engine                     │
│  ┌─────────┐ ┌──────────┐ ┌─────────────┐  │
│  │ Parser  │ │ Planner  │ │ Executor    │  │
│  └─────────┘ └──────────┘ └─────────────┘  │
│  (Cypher → Logical Plan → Physical Plan)   │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Storage Engine                   │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐  │
│  │ Buffer   │ │ WAL      │ │ Checkpoint │  │
│  │ Manager  │ │ Manager  │ │ Manager    │  │
│  └──────────┘ └──────────┘ └────────────┘  │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│          Columnar Storage                  │
│  (Memory-mapped, column-oriented data)      │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│         .cgraph file + .wal file           │
│         (Persistent storage)                │
└─────────────────────────────────────────────┘
```

## Core Components

### 1. napi-rs Bindings

- **File:** `src/lib.rs`
- **Purpose:** Bridge between JavaScript and Rust
- **Technology:** napi-rs with neon Serde serialization

```rust
#[napi]
impl Database {
    #[napi(constructor)]
    pub fn new(path: Option<String>) -> Self {
        // ...
    }

    #[napi]
    pub fn init(&mut self) {
        // ...
    }
}
```

### 2. Query Engine

- **Directory:** `src/query/`
- **Components:**
  - **Parser:** Cypher → AST (using `nom`)
  - **Planner:** AST → Logical Plan
  - **Optimizer:** Logical Plan → Optimized Plan
  - **Executor:** Parallel execution using `rayon`

### 3. Storage Engine

- **Directory:** `src/storage/`
- **Components:**
  - **Buffer Manager:** Page caching with LRU eviction
  - **WAL Manager:** Write-ahead logging for durability
  - **Checkpoint Manager:** Periodic WAL to main file flush
  - **Page Manager:** Memory-mapped file I/O

### 4. Table Management

- **Directory:** `src/table/`
- **Components:**
  - **Node Table:** Columnar storage for nodes
  - **Rel Table:** Adjacency lists for relationships
  - **Schema Manager:** Type validation and constraints

### 5. Index Structures

- **Directory:** `src/index/`
- **Components:**
  - **HNSW Index:** Vector similarity search
  - **Hash Index:** Fast exact match lookups
  - **B-tree Index:** Range queries (planned)

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Rust (edition 2021) |
| FFI | napi-rs |
| Async | Tokio (planned) |
| Parallelism | Rayon |
| Parsing | nom |
| Serialization | Serde, bincode |
| Compression | snap (Snappy) |
| Hashing | ahash |
| Random | rand |

## Data Flow

### Read Path

```
1. Application calls conn.query()
   ↓
2. Parse Cypher query
   ↓
3. Plan and optimize
   ↓
4. Execute with parallel workers
   ↓
5. Read from buffer pool (or disk)
   ↓
6. Serialize results to JavaScript
   ↓
7. Return QueryResult
```

### Write Path

```
1. Application calls conn.query()
   ↓
2. Parse and validate
   ↓
3. Write to WAL (sync)
   ↓
4. Update in-memory structures
   ↓
5. Return success
   ↓
6. Background: Checkpoint to main file
```

## Concurrency Model

- **Readers:** Unlimited concurrent reads
- **Writers:** Single-writer concurrency (WAL serialization)
- **Isolation:** Serializable snapshot isolation
- **Locking:** Wait-free data structures where possible

## Memory Management

- **Buffer Pool:** Fixed-size page cache (configurable)
- **Page Size:** 4KB default
- **Eviction:** LRU with clock algorithm
- **Mapping:** Memory-mapped I/O with `memmap2`

## Error Handling

- **Strategy:** Structured errors with `thiserror`
- **Propagation:** Errors bubble through napi-rs to JavaScript
- **Recovery:** WAL replay on startup

## See Also

- [Storage Format](storage-format.md) — On-disk structure
- [Query Execution](query-execution.md) — Query processing details
