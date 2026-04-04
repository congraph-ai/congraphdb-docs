# Optimistic Concurrency Control (OCC)

CongraphDB v0.1.8+ includes production-ready Optimistic Concurrency Control for high-concurrency scenarios.

## What is OCC?

Optimistic Concurrency Control (OCC) is a concurrency control method that allows multiple transactions to proceed without blocking. Instead of locking resources when reading data, OCC tracks what data each transaction reads and writes, validating at commit time that no conflicts occurred.

### OCC vs Pessimistic Locking

| Aspect | OCC | Pessimistic Locking |
|--------|-----|---------------------|
| **Locking** | No locks during reads/writes | Locks held during reads/writes |
| **Conflict Detection** | At commit time | At access time |
| **Best For** | Low-contention workloads | High-contention workloads |
| **Throughput** | Higher under low contention | More predictable under contention |
| **Latency** | Lower read latency | Higher due to locks |

## How OCC Works in CongraphDB

### 1. Read Phase

During a transaction, CongraphDB tracks:
- **Read Set**: All nodes and relationships read by the transaction
- **Write Set**: All nodes and relationships to be modified

Each row has a version number that is read without locks:

```javascript
conn.beginTransaction();

// Read user - version is recorded in read set
const result = await conn.query(`
  MATCH (u:User {id: 'alice'})
  RETURN u.balance, u._version
`);
```

### 2. Validation Phase

At commit time, CongraphDB validates:
- No transaction in the read set has been modified by another committed transaction
- All versions are still consistent with what was read

```javascript
// Automatic validation happens here
await conn.commitWithOccSync(10); // max 10 retries on conflict
```

### 3. Write Phase

If validation passes:
- Changes are applied to the database
- Version numbers are incremented atomically
- Transaction is committed

### 4. Retry on Conflict

If validation fails (another transaction modified data you read):
- Transaction is rolled back
- Automatic retry with exponential backoff
- Up to configurable number of retry attempts

## Using OCC in Your Application

### Basic OCC Transaction

```javascript
const { Database } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const conn = db.createConnection();

conn.beginTransaction();

try {
  // Read account balance (records version)
  const result = await conn.query(`
    MATCH (a:Account {id: 'alice'})
    RETURN a.balance
  `);

  // ... application logic ...

  // Write new balance
  await conn.query(`
    MATCH (a:Account {id: 'alice'})
    SET a.balance = a.balance - 100
  `);

  // Commit with OCC - automatic retry on conflict
  await conn.commitWithOccSync(5); // max 5 retries

} catch (error) {
  conn.rollback();
  console.error('Transaction failed:', error);
}
```

### Execute with Retry Wrapper

For automatic retry around any operation:

```javascript
const result = await conn.executeWithRetrySync(5, () => {
  return conn.query(`
    MATCH (u:User {id: 'alice'})
    SET u.lastLogin = ${Date.now()}
    RETURN u
  `);
});
```

### OCC Statistics

Monitor your application's concurrency patterns:

```javascript
const stats = await conn.getOccStatistics();
console.log(stats);

// Output:
// {
//   successful_transactions: 1250,
//   failed_transactions: 5,
//   conflicts_detected: 23,
//   total_retries: 18,
//   max_retry_count: 3,
//   conflict_rate: 1.84  // percentage
// }
```

### Reset Statistics

```javascript
await conn.resetOccStatistics();
```

## Configuration

### Version Cache

CongraphDB uses an LRU cache for version lookups to reduce overhead:

```javascript
// Get current cache size
const cacheSize = await conn.getVersionCacheSize();

// Clear the cache
await conn.clearVersionCache();
```

### Adaptive Retry System

CongraphDB includes an adaptive retry system that adjusts retry behavior based on conflict rate:

- Under low contention (<5% conflict rate): Standard retry with exponential backoff
- Under high contention (>20% conflict rate): Up to 3x more retries with jitter
- Backoff formula: `base_delay * (2 ^ attempt_count) + random_jitter`

## Best Practices

### 1. Keep Transactions Short

```javascript
// Good: Short transaction
conn.beginTransaction();
const result = await conn.query('MATCH (u:User {id: $id}) RETURN u', { id: 'alice' });
await conn.query('SET u.lastSeen = $ts', { ts: Date.now() });
await conn.commitWithOccSync(5);

// Avoid: Long-running transactions
conn.beginTransaction();
const result = await conn.query('MATCH (u:User) RETURN u'); // 10k rows
await slowExternalApiCall(result); // Don't do this!
await conn.commitWithOccSync(5); // High chance of conflict
```

### 2. Minimize Read Set Size

```javascript
// Better: Read only what you need
conn.beginTransaction();
await conn.query('MATCH (u:User {id: $id}) RETURN u.balance', { id: 'alice' });
await conn.query('MATCH (u:User {id: $id}) SET u.balance = u.balance - 100', { id: 'alice' });
await conn.commitWithOccSync(5);

// Worse: Read many rows you won't modify
conn.beginTransaction();
await conn.query('MATCH (u:User) RETURN u'); // All users!
await conn.query('MATCH (u:User {id: "alice"}) SET u.balance = u.balance - 100');
await conn.commitWithOccSync(5); // Unnecessarily large read set
```

### 3. Handle Conflicts Gracefully

```javascript
async function transferWithRetry(fromId, toId, amount, maxRetries = 5) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      conn.beginTransaction();

      await conn.query(`
        MATCH (a:Account {id: $fromId})
        SET a.balance = a.balance - $amount
      `, { fromId, amount });

      await conn.query(`
        MATCH (a:Account {id: $toId})
        SET a.balance = a.balance + $amount
      `, { toId, amount });

      await conn.commitWithOccSync(1); // One retry at commit level

      return { success: true };

    } catch (error) {
      conn.rollback();

      if (attempt === maxRetries - 1) {
        return { success: false, error: error.message };
      }

      // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 100));
    }
  }
}
```

## Monitoring OCC Performance

### Track Conflict Rates

```javascript
setInterval(async () => {
  const stats = await conn.getOccStatistics();

  if (stats.conflict_rate > 10) {
    console.warn(`High conflict rate: ${stats.conflict_rate}%`);
    console.warn('Consider: reducing transaction size, adding backoff, or using pessimistic locking');
  }

  console.log(`OCC Stats: ${stats.successful_transactions} successful, ${stats.conflicts_detected} conflicts`);
}, 60000); // Every minute
```

### Performance Metrics

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **Conflict Rate** | < 5% | 5-20% | > 20% |
| **Avg Retries** | < 1.1 | 1.1-2 | > 2 |
| **Max Retry Count** | 1-2 | 3-5 | > 5 |

## When to Use OCC

### Use OCC When:
- Read-heavy workloads
- Low to moderate contention
- Short transactions
- Need for low read latency
- Can tolerate occasional retries

### Consider Alternatives When:
- Very high write contention on same data
- Long-running transactions
- Cannot tolerate retries
- Need predictable worst-case latency

## Next Steps

- [Transactions](transactions.md) — Transaction basics
- [Performance](performance.md) — Performance optimization
