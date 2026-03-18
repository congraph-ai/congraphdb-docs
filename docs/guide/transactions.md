# Transactions

CongraphDB provides ACID transactions to ensure data consistency and integrity.

## ACID Guarantees

- **Atomicity** — All operations in a transaction succeed or none do
- **Consistency** — Database always moves from one valid state to another
- **Isolation** — Concurrent transactions don't interfere with each other
- **Durability** — Committed changes persist even after system failure

## Basic Transactions

### Starting a Transaction

```javascript
const conn = db.createConnection();
conn.beginTransaction();

try {
  // Your operations here
  await conn.query(`CREATE (u:User {name: 'Alice', age: 30})`);
  await conn.query(`CREATE (u:User {name: 'Bob', age: 25})`);

  // Commit if all succeeds
  conn.commit();
} catch (error) {
  // Rollback on error
  conn.rollback();
  throw error;
}
```

### Checking Transaction State

```javascript
console.log(conn.inTransaction());  // true or false
```

## Write-Ahead Logging (WAL)

CongraphDB uses a write-ahead log for crash recovery:

1. All changes are first written to the `.wal` file
2. Changes are applied to the main database file
3. WAL is periodically checkpointed and cleared

This ensures that if the process crashes, uncommitted changes can be rolled back and committed changes can be recovered.

## Transaction Isolation

CongraphDB uses **serializable isolation** — the strongest isolation level. This means:

- Concurrent transactions appear to execute sequentially
- No dirty reads, non-repeatable reads, or phantom reads
- Guaranteed consistency without manual locking

## Performance Considerations

### Minimize Transaction Duration

```javascript
// Good: Short transaction
conn.beginTransaction();
await conn.query(`CREATE (u:User {name: 'Alice'})`);
conn.commit();

// Avoid: Long-running transactions
conn.beginTransaction();
await slowExternalOperation();  // Don't do this!
await conn.query(`CREATE (u:User {name: 'Alice'})`);
conn.commit();
```

### Batch Operations

```javascript
conn.beginTransaction();

for (let i = 0; i < 1000; i++) {
  await conn.query(`CREATE (u:User {name: 'User${i}', age: ${i}})`);
}

conn.commit();
```

## Auto-Checkpoint

CongraphDB automatically checkpoints the WAL based on the threshold configured when creating the database:

```javascript
const db = new Database('./my-graph.cgraph', {
  autoCheckpoint: true,
  checkpointThreshold: 1000  // Checkpoint after 1000 operations
});
```

You can also manually trigger a checkpoint:

```javascript
db.checkpoint();
```

## Complete Example

```javascript
const { Database } = require('congraphdb');

async function transferFriendship(fromUser, toUser, newFriend) {
  const db = new Database('./social-graph.cgraph');
  db.init();
  const conn = db.createConnection();

  conn.beginTransaction();

  try {
    // Verify users exist
    const fromResult = await conn.query(`
      MATCH (u:User {name: $name}) RETURN u
    `, { name: fromUser });

    if (fromResult.getNext() === null) {
      throw new Error(`User ${fromUser} not found`);
    }

    const toResult = await conn.query(`
      MATCH (u:User {name: $name}) RETURN u
    `, { name: toUser });

    if (toResult.getNext() === null) {
      throw new Error(`User ${toUser} not found`);
    }

    // Remove old relationship
    await conn.query(`
      MATCH (u:User {name: $from})-[k:Knows]->(v:User {name: $to})
      DELETE k
    `, { from: fromUser, to: toUser });

    // Create new relationship
    await conn.query(`
      MATCH (u:User {name: $from})
      MATCH (v:User {name: $to})
      CREATE (u)-[:Knows {since: $when}]->(v)
    `, { from: toUser, to: newFriend, when: Date.now() });

    conn.commit();
    console.log('Friendship transferred successfully');
  } catch (error) {
    conn.rollback();
    console.error('Transaction failed:', error.message);
    throw error;
  } finally {
    db.close();
  }
}

transferFriendship('Alice', 'Bob', 'Charlie').catch(console.error);
```

## Next Steps

- [Vector Search](vector-search.md) — Semantic search with embeddings
- [Performance](performance.md) — Optimization tips
