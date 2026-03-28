# Storage Format

CongraphDB uses a single-file storage format similar to SQLite, with a separate write-ahead log.

## File Structure

```
my-graph.cgraph     # Main database file
my-graph.wal        # Write-ahead log (transient)
```

## Storage Layer Architecture

The storage layer is organized into several modules in `src/storage/`:

```
src/storage/
├── mod.rs           # Module exports
├── manager.rs       # StorageManager - main storage interface
├── page_manager.rs  # PageManager - memory-mapped file I/O
├── file_handle.rs   # FileHandle - low-level file operations
├── page.rs          # Page abstraction and page types
├── buffer/          # Buffer management
│   └── manager.rs   # BufferManager - page caching
├── catalog/         # Schema catalog
│   ├── mod.rs
│   └── catalog.rs   # Catalog - schema persistence
└── wal/             # Write-ahead logging
    ├── mod.rs
    └── wal.rs       # WAL implementation
```

## Main Database File (.cgraph)

### File Layout

```
┌─────────────────────────────────────────────┐
│           Header Page (Page 0)              │
│  - Magic number: "CGRAPH\0"                │
│  - Version: 4 bytes                         │
│  - Page size: 4 bytes                       │
│  - Checksum: 8 bytes                        │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Catalog Pages                   │
│  - Table catalog entries                    │
│  - Node/Rel table definitions               │
│  - Property definitions                     │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│           Data Pages                       │
│  - Node data (columnar)                     │
│  - Relationship data (adjacency lists)      │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Index Pages                     │
│  - HNSW graphs                             │
│  - Hash indexes                            │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Free Pages                      │
│  - Reusable page list                      │
└─────────────────────────────────────────────┘
```

## Page Structure

### Page Types

Each page has a type defined in `src/storage/page.rs`:

| PageType | Value | Description |
|----------|-------|-------------|
| Header | 0 | Header page (page 0) |
| Catalog | 1 | Catalog metadata |
| Data | 2 | User data |
| Free | 3 | Free/reusable page |
| Wal | 4 | WAL page |
| Index | 5 | Index data |

### Page Header

Each page begins with a 16-byte header:

```rust
pub struct PageHeader {
    pub page_type: PageType,  // 1 byte
    pub version: u32,         // 4 bytes
    pub checksum: u32,        // 4 bytes
    // 7 bytes reserved
}
```

### Page Content

```
┌─────────────────────────────────────────────┐
│  Page Header (16 bytes)                    │
│  - Page type: 1 byte                       │
│  - Version: 4 bytes                        │
│  - Checksum: 4 bytes                       │
│  - Reserved: 7 bytes                       │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  Page Content (4080 bytes)                 │
│  - Type-dependent data                     │
└─────────────────────────────────────────────┘
```

## Catalog

The catalog stores all schema information in `src/storage/catalog/catalog.rs`:

### Catalog Structure

```rust
pub struct Catalog {
    tables: HashMap<String, TableCatalogEntry>,
    table_ids: HashMap<TableId, String>,
    next_table_id: TableId,
    version: u64,
}
```

### Table Catalog Entry

```rust
pub struct TableCatalogEntry {
    pub id: TableId,
    pub name: String,
    pub table_type: TableType,  // Node or Rel
    pub properties: Vec<PropertyDefinition>,
    pub primary_key: Option<String>,
    pub indices: Vec<IndexDefinition>,
    pub from_table_id: Option<TableId>,  // For Rel tables
    pub to_table_id: Option<TableId>,    // For Rel tables
}
```

### Property Definition

```rust
pub struct PropertyDefinition {
    pub name: String,
    pub logical_type: LogicalType,
}
```

## Columnar Storage

Node tables are stored column-wise for analytical performance:

### Traditional Row Storage

```
┌──────┬─────┬───────┐
│ name │ age │ email │  Row 1
├──────┼─────┼───────┤
│ Alice│  30 │  ...  │  Row 2
└──────┴─────┴───────┘
```

### CongraphDB Columnar Storage

```
┌──────────┐  ┌─────┐  ┌──────────┐
│   name   │  │ age │  │  email   │  Separate columns
├──────────┤  ├─────┤  ├──────────┤
│  Alice   │  │  30 │  │  ...     │
│  Bob     │  │  25 │  │  ...     │
└──────────┘  └─────┘  └──────────┘
```

### Benefits of Columnar Storage

1. **Compression** — Similar values compress better
2. **Analytics** — `AVG(age)` reads only age column
3. **Caching** — Hot columns stay in memory

## Relationship Storage

Relationships use adjacency lists with forward/backward indexing:

```
┌─────────────────────────────────────────────────┐
│  Relationship Table: KNOWS (FROM User TO User)  │
├─────────────────────────────────────────────────┤
│  Forward Adjacency List:                        │
│    Alice -> [Bob, Charlie, David]               │
│    Bob -> [Alice, Eve]                          │
├─────────────────────────────────────────────────┤
│  Backward Adjacency List:                       │
│    Bob <- [Alice, Charlie]                      │
│    Alice <- [Bob]                               │
└─────────────────────────────────────────────────┘
```

## Buffer Management

The buffer manager in `src/storage/buffer/manager.rs` handles page caching:

### Buffer Pool

- Fixed-size page cache (configurable)
- LRU eviction policy
- Page size: 4KB default (defined in core)

### Page Access

```
Read Request
    ↓
Check Buffer Pool
    ↓
    ├─ Hit: Return cached page
    │
    └─ Miss: Load from disk
            ↓
        Add to buffer pool
            ↓
        Evict if necessary
            ↓
        Return page
```

## Vector Storage

Vectors (embeddings) are stored contiguously:

```
┌─────────────────────────────────────────────────┐
│  FLOAT_VECTOR[128] Column                      │
├─────────────────────────────────────────────────┤
│  [v1_1, v1_2, ..., v1_128]    // Document 1   │
│  [v2_1, v2_2, ..., v2_128]    // Document 2   │
│  [v3_1, v3_2, ..., v3_128]    // Document 3   │
└─────────────────────────────────────────────────┘
```

This enables efficient SIMD operations and HNSW indexing.

## Write-Ahead Log (.wal)

The WAL records all mutations before they're written to the main file.

### WAL Format

```
┌─────────────────────────────────────────────┐
│  WAL Header (256 bytes)                     │
│  - Magic: "CGWAL\0"                         │
│  - Sequence number                          │
│  - Checkpoint position                      │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  Transaction Records                       │
│  ┌─────────────────────────────────────┐   │
│  │ BEGIN_TXN                          │   │
│  │ - TXN ID: 12345                    │   │
│  │ - Timestamp                        │   │
│  ├─────────────────────────────────────┤   │
│  │ INSERT_NODE                        │   │
│  │ - Table: User                      │   │
│  │ - Data: {name: "Alice", age: 30}   │   │
│  ├─────────────────────────────────────┤   │
│  │ INSERT_REL                         │   │
│  │ - Table: Knows                     │   │
│  │ - From: Alice                      │   │
│  │ - To: Bob                          │   │
│  │ - Data: {since: 2020}              │   │
│  ├─────────────────────────────────────┤   │
│  │ COMMIT_TXN                         │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Checkpointing

Periodically, the WAL is flushed to the main file:

```
1. Acquire checkpoint lock
2. Flush all dirty pages to disk
3. Write checkpoint record to WAL
4. Truncate WAL
5. Release lock
```

## Checksums

All pages include CRC32 checksums:

- **Detection**: Corrupted pages detected on read
- **Recovery**: WAL replay restores consistent state
- **Performance**: Checksums computed during flush

## Compression

Optional Snappy compression for column data:

```
Uncompressed: [1, 2, 3, 1, 2, 3, 1, 2, 3, ...]  // 100 bytes
Compressed:  [1, 2, 3] x 33                        // 20 bytes
```

Compression is most effective for:
- Low-cardinality columns
- Repeated values
- Sparse data

## File Size Management

As data is deleted, pages become free:

```
┌─────────────────────────────────────────────┐
│  Free Page List                             │
│  - Tracks reusable pages                    │
│  - Coalesced when possible                  │
│  - Reduces file fragmentation               │
└─────────────────────────────────────────────┘
```

## Configuration

```javascript
const db = new Database('./my-graph.cgraph', {
  // Page buffer size
  bufferSize: 1024 * 1024 * 100,  // 100MB

  // WAL behavior
  autoCheckpoint: true,
  checkpointThreshold: 1000000,  // operations

  // Data integrity
  enableChecksums: true
});
```

## See Also

- [Transaction Log](transaction-log.md) — WAL implementation details
- [Architecture](architecture.md) — System overview
- [Index Structures](index-structures.md) — HNSW details
