# Transaction Log

The Write-Ahead Log (WAL) ensures ACID durability for CongraphDB.

## Purpose

The WAL provides:

1. **Durability** — Committed transactions survive crashes
2. **Atomicity** — All-or-nothing transaction guarantees
3. **Crash Recovery** — Restore consistent state after failure
4. **Checkpointing** — Periodic flush to main file

## WAL Architecture

```
┌─────────────────────────────────────────────────┐
│               Application                       │
│                 Query Layer                     │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              Transaction Manager                │
│  - Begin, Commit, Rollback                     │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│               WAL Manager                       │
│  - Append-only writes                           │
│  - Sync to disk                                 │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              my-graph.wal                       │
│  (Sequential append log)                        │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│           Checkpoint Manager                    │
│  - Periodic WAL flush to main file              │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              my-graph.cgraph                    │
│  (Main database file)                           │
└─────────────────────────────────────────────────┘
```

## WAL Record Types

| Record Type | Description |
|-------------|-------------|
| `BEGIN_TXN` | Start a new transaction |
| `COMMIT_TXN` | Commit transaction |
| `ROLLBACK_TXN` | Rollback transaction |
| `INSERT_NODE` | Insert node record |
| `INSERT_REL` | Insert relationship record |
| `DELETE_NODE` | Delete node record |
| `DELETE_REL` | Delete relationship record |
| `UPDATE_PROPERTY` | Update property value |
| `CHECKPOINT` | Checkpoint marker |

## Record Format

Each WAL record has a fixed header and variable payload:

```
┌─────────────────────────────────────────────────┐
│  Record Header (24 bytes)                      │
│  ┌───────────────────────────────────────────┐  │
│  │ Record Type: 4 bytes                     │  │
│  │ Transaction ID: 8 bytes                  │  │
│  │ Payload Size: 4 bytes                    │  │
│  │ Timestamp: 8 bytes                       │  │
│  └───────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│  Payload (variable)                            │
│  - Type-dependent data                         │
├─────────────────────────────────────────────────┤
│  Checksum (4 bytes)                            │
│  - CRC32 of header + payload                   │
└─────────────────────────────────────────────────┘
```

## Transaction Lifecycle

### 1. Begin Transaction

```
1. Generate unique transaction ID
2. Write BEGIN_TXN record to WAL
3. Sync WAL to disk (fsync)
4. Return transaction handle
```

### 2. Execute Operations

```
For each operation:
  1. Encode operation record
  2. Append to WAL
  3. Update in-memory structures
  4. Continue (no per-op sync)
```

### 3. Commit Transaction

```
1. Write COMMIT_TXN record to WAL
2. Sync WAL to disk (fsync)
3. Mark transaction as committed
4. Return success
```

### 4. Rollback Transaction

```
1. Write ROLLBACK_TXN record to WAL
2. Undo in-memory changes
3. Sync WAL to disk
4. Return success
```

## Crash Recovery

On startup, CongraphDB replays the WAL:

```
1. Read WAL header for checkpoint position
2. Scan WAL from checkpoint position
3. For each transaction:
   a. If COMMIT_TXN found: Replay operations
   b. If ROLLBACK_TXN found: Skip operations
   c. If incomplete: Skip (transaction never committed)
4. Consistent state achieved
5. Open database
```

### Recovery Algorithm

```
replay_wal():
  checkpoint_pos = read_checkpoint_position()
  wal = open_wal()
  seek(wal, checkpoint_pos)

  active_txns = {}

  while has_more_records(wal):
    record = read_record(wal)

    match record.type:
      BEGIN_TXN:
        active_txns[record.txn_id] = []

      INSERT_NODE, INSERT_REL, UPDATE, DELETE:
        if record.txn_id in active_txns:
          active_txns[record.txn_id].push(record)

      COMMIT_TXN:
        if record.txn_id in active_txns:
          replay(active_txns[record.txn_id])
          del active_txns[record.txn_id]

      ROLLBACK_TXN:
        del active_txns[record.txn_id]

  # Any transactions left were incomplete - ignore them
```

## Checkpointing

Periodically, the WAL is flushed to the main database file:

### Checkpoint Process

```
1. Acquire checkpoint lock
2. Flush all dirty pages to main file
3. Write CHECKPOINT record with current LSN
4. Truncate WAL up to checkpoint LSN
5. Release lock
```

### Checkpoint Triggers

| Trigger | Description |
|---------|-------------|
| Periodic | Time-based checkpoint (e.g., every 5 minutes) |
| Size-based | WAL size exceeds threshold |
| Manual | Explicit `db.checkpoint()` call |
| Idle | Checkpoint when database is idle |

## Performance Considerations

### Sync Overhead

WAL writes are synced to disk for durability:

```
Option 1: Every operation (safest, slowest)
  write(record); fsync();

Option 2: Every transaction (default)
  write(record); ...; write(commit); fsync();

Option 3: Batch sync (fastest, riskiest)
  write(record); ...; write(commit);
  (fsync happens periodically)
```

CongraphDB uses **Option 2** (sync on commit).

### WAL Size Management

```
Large WAL → Long recovery → Slower startup
Small WAL → Frequent checkpoints → More I/O overhead

Balanced approach:
  - Checkpoint when WAL exceeds threshold (default: 1M operations)
  - Or checkpoint periodically (default: 5 minutes)
```

## Configuration

```javascript
const db = new Database('./my-graph.cgraph', {
  // WAL behavior
  autoCheckpoint: true,
  checkpointThreshold: 1000000,  // operations

  // Error handling
  throwOnWalReplayFailure: true,

  // Data integrity
  enableChecksums: true
});
```

## See Also

- [Storage Format](storage-format.md) — On-disk structure
- [Architecture](architecture.md) — System overview
- [Transactions](../guide/transactions.md) — Using transactions
