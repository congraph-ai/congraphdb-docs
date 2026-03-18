# Migration Guide

Guide for upgrading between versions of CongraphDB.

## Version 0.0.x to 0.1.x

### Breaking Changes

None. 0.1.x is backward compatible with 0.0.x.

### New Features

- Improved query optimizer
- Better error messages
- Performance improvements

### Migration Steps

1. **Backup your database**:
   ```javascript
   const fs = require('fs');
   fs.copyFileSync('./my-graph.cgraph', './my-graph.backup');
   fs.copyFileSync('./my-graph.wal', './my-graph.wal.backup');
   ```

2. **Update package**:
   ```bash
   npm update congraphdb
   ```

3. **Test your application**:
   - Run your test suite
   - Verify query results
   - Check performance

4. **Deploy** when confident

### Storage Version

Storage version may change between major versions:

```javascript
// Check storage version
const currentVersion = Database.getStorageVersion();
console.log('Storage version:', currentVersion);

// v0.1.x uses storage version 1
```

## Upgrading Best Practices

### Before Upgrading

1. **Test in staging**:
   - Copy production database to staging
   - Run full test suite
   - Monitor performance

2. **Review changelog**:
   - Read [CHANGELOG](changelog.md) for breaking changes
   - Check GitHub issues for known problems

3. **Plan rollback**:
   - Keep backups accessible
   - Document downgrade process

### During Upgrade

1. **Stop your application**
2. **Backup database files** (.cgraph and .wal)
3. **Update package**
4. **Restart application**
5. **Monitor logs for errors**

### After Upgrade

1. **Verify functionality**:
   - Key operations working
   - Query results correct
   - Performance acceptable

2. **Monitor for issues**:
   - Error rates
   - Query latency
   - Memory usage

3. **Keep backup** until confident

## Rollback Procedure

If you need to rollback:

1. **Stop your application**
2. **Restore from backup**:
   ```bash
   cp my-graph.backup my-graph.cgraph
   cp my-graph.wal.backup my-graph.wal
   ```
3. **Reinstall previous version**:
   ```bash
   npm install congraphdb@0.1.0
   ```
4. **Restart application**

## Data Migration

### Schema Changes

When schema changes between versions:

```javascript
// Check for migration needed
const db = new Database('./my-graph.cgraph');
db.init();

const conn = db.createConnection();

// Query storage version
const result = conn.querySync(`
  CALL db.storageVersion()
`);

console.log('Storage version:', result.getNext().version);
```

### Automatic Migrations

CongraphDB handles automatic migrations for compatible changes:

- New column types (if compatible)
- Index structure changes
- Storage format improvements

### Manual Migrations

For breaking schema changes, you may need to export and reimport:

```javascript
// Export data
const data = await conn.query(`
  MATCH (n) RETURN n
`);

// Upgrade to new version

// Reimport data
for (const row of data) {
  await conn.query(`
    CREATE (n:NewSchema {props})
  `, { props: row.n });
}
```

## Storage Version Compatibility

| App Version | Storage Version | Notes |
|-------------|-----------------|-------|
| 0.0.x | 1 | Initial release |
| 0.1.x | 1 | Backward compatible |

Older app versions can open newer databases only if storage version is compatible.

## See Also

- [Changelog](changelog.md) — Version history
- [Storage Format](../internals/storage-format.md) — Internal format details
