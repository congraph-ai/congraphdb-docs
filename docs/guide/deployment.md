# Deployment

This guide covers deploying CongraphDB in production environments.

## Deployment Scenarios

CongraphDB is designed for **local-first** and **edge** deployments:

- **Desktop applications** — Electron, Tauri
- **Serverless functions** — AWS Lambda, Cloudflare Workers
- **Edge computing** — Cloudflare Workers, Vercel Edge
- **Embedded devices** — IoT, edge appliances
- **Backend services** — Node.js microservices

## Production Checklist

- [ ] Enable compression
- [ ] Configure appropriate buffer size
- [ ] Set up automatic backups
- [ ] Monitor WAL file size
- [ ] Handle database upgrades
- [ ] Plan for scaling

## Configuration

### Production Database Settings

```javascript
const db = new Database('./production.cgraph', {
  // Memory management
  bufferManagerSize: 512 * 1024 * 1024,  // 512MB

  // Enable compression
  enableCompression: true,

  // WAL management
  autoCheckpoint: true,
  checkpointThreshold: 1000,

  // Data integrity
  enableChecksums: true,
  throwOnWalReplayFailure: true,

  // Size limits
  maxDBSize: 10 * 1024 * 1024 * 1024  // 10GB
});
```

### Read-Only Mode

For scenarios where you don't need writes:

```javascript
const db = new Database('./production.cgraph', {
  readOnly: true
});
```

## Backup Strategy

### Method 1: File Copy

```javascript
const fs = require('fs');

function backupDatabase(dbPath, backupPath) {
  const db = new Database(dbPath);
  db.init();

  // Force checkpoint to flush WAL
  db.checkpoint();

  // Copy both files
  fs.copyFileSync(dbPath, backupPath);
  fs.copyFileSync(dbPath + '.wal', backupPath + '.wal');

  db.close();
}
```

### Method 2: Scheduled Backups

```javascript
const cron = require('node-cron');

// Daily backup at 2 AM
cron.schedule('0 2 * * *', () => {
  const timestamp = new Date().toISOString().split('T')[0];
  backupDatabase(
    './production.cgraph',
    `./backups/production-${timestamp}.cgraph`
  );
});
```

## High Availability

### Read Replicas

```javascript
// Primary (read-write)
const primary = new Database('./primary.cgraph');
primary.init();

// Replica (read-only)
const replica = new Database('./replica.cgraph', { readOnly: true });
replica.init();

// Sync function
async function syncReplica() {
  primary.checkpoint();
  copyFile('./primary.cgraph', './replica.cgraph');
  copyFile('./primary.cgraph.wal', './replica.cgraph.wal');
}
```

## Serverless Deployment

### AWS Lambda

```javascript
const { Database } = require('@congraph-ai/congraphdb');
const path = require('path');

// Lambda persistence layer
const DB_PATH = path.join('/tmp', 'lambda.cgraph');

let db;

exports.handler = async (event) => {
  if (!db) {
    db = new Database(DB_PATH);
    db.init();
  }

  const conn = db.createConnection();
  const result = await conn.query(event.query);

  return {
    statusCode: 200,
    body: JSON.stringify(result.getAll())
  };
};
```

### Cloudflare Workers

For edge deployments, consider using Cloudflare D1 or Workers KV for persistence, and use CongraphDB for in-memory processing.

## Monitoring

### Health Checks

```javascript
function healthCheck(db) {
  try {
    const conn = db.createConnection();
    const result = conn.querySync('MATCH (u:User) RETURN COUNT(u) AS count');
    const row = result.getNext();
    result.close();
    conn.close();

    return {
      healthy: true,
      nodeCount: row.count
    };
  } catch (error) {
    return {
      healthy: false,
      error: error.message
    };
  }
}
```

### Metrics to Track

- Database file size
- WAL file size
- Buffer hit rate
- Query latency
- Transaction throughput
- Checkpoint frequency

## Scaling Strategies

### Vertical Scaling

- Increase buffer manager size
- Use faster storage (SSD/NVMe)
- More CPU cores for parallel execution

### Horizontal Scaling

- **Sharding**: Distribute data across multiple database files
- **Read replicas**: Multiple read-only copies
- **Caching**: Use Redis for hot data

### Data Partitioning

```javascript
// Shard by user ID
function getShardPath(userId) {
  const shardId = userId % 4;
  return `./shards/shard-${shardId}.cgraph`;
}

async function queryUser(userId) {
  const dbPath = getShardPath(userId);
  const db = new Database(dbPath);
  db.init();

  const conn = db.createConnection();
  const result = await conn.query(`
    MATCH (u:User {id: $userId})
    RETURN u
  `, { userId });

  db.close();
  return result.getNext();
}
```

## Security

### File Permissions

```javascript
const fs = require('fs');
const DB_PATH = './production.cgraph';

// Set restrictive permissions
fs.chmodSync(DB_PATH, 0o600);  // Owner read/write only
fs.chmodSync(DB_PATH + '.wal', 0o600);
```

### Encryption

For sensitive data, consider:
- Encrypting at rest using filesystem encryption (LUKS, BitLocker)
- Encrypting specific fields in application layer
- Using secure enclaves for processing

## Migration and Upgrades

### Version Compatibility

When upgrading CongraphDB versions:

1. **Backup your database** before upgrading
2. Check [CHANGELOG](../releases/changelog.md) for breaking changes
3. Test migration in staging first

### Storage Version

```javascript
// Check storage version compatibility
const storageVersion = Database.getStorageVersion();
console.log('Storage version:', storageVersion);
```

## Next Steps

- [Internals](../internals/index.md) — Deep dive into architecture
- [API Reference](../api/index.md) — Complete API documentation
