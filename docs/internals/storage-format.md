# Storage Format

CongraphDB uses a single-file storage format similar to SQLite, with a separate write-ahead log.

## File Structure

```
my-graph.cgraph     # Main database file
my-graph.wal        # Write-ahead log (transient)
```

## Main Database File (.cgraph)

### File Layout

```
┌─────────────────────────────────────────────┐
│           Header (1024 bytes)              │
│  - Magic number: "CGRAPH\0"                │
│  - Version: 4 bytes                         │
│  - Page size: 4 bytes                       │
│  - Number of tables: 4 bytes                │
│  - Checksum: 8 bytes                        │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Table Catalog Pages             │
│  - Table names, types, schemas             │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│           Data Pages (Columnar)            │
│  - Node tables: column chunks               │
│  - Relationship tables: adjacency lists     │
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

### Page Structure

Each page is 4KB (default) and contains:

```
┌─────────────────────────────────────────────┐
│  Page Header (16 bytes)                    │
│  - Page type: DATA, CATALOG, INDEX, FREE   │
│  - Page ID: 8 bytes                        │
│  - Checksum: CRC32                         │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  Page Content (4064 bytes)                 │
│  - Type-dependent data                     │
└─────────────────────────────────────────────┘
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

- **Detection:** Corrupted pages detected on read
- **Recovery:** WAL replay restores consistent state
- **Performance:** Checksums computed during flush

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

## See Also

- [Transaction Log](transaction-log.md) — WAL implementation details
- [Architecture](architecture.md) — System overview
