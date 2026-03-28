# JavaScript/TypeScript API

Complete API reference for CongraphDB Node.js bindings.

CongraphDB provides **three ways to query your graph**:

1. **Cypher Query Language** - Industry-standard graph query language
2. **JavaScript Native API** - Programmatic CRUD operations (CongraphDBAPI)
3. **Navigator API** - Fluent graph traversal

> **Note:** This page covers the native Database/Connection/QueryResult bindings. For the JavaScript Native API (CongraphDBAPI), see [JavaScript API Reference](./javascript-api.md). For guidance on choosing an interface, see [Choosing Your Query Interface](../guide/choosing-interface.md).

---

## Quick Interface Comparison

```javascript
// Option 1: Cypher Query Language
const result = await conn.query(`
  MATCH (u:User {name: 'Alice'})-[:KNOWS]->(f:User)
  RETURN f.name
`);

// Option 2: JavaScript Native API
const api = new CongraphDBAPI(db);
const friends = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
});

// Option 3: Navigator API
const friends = await api.nav(alice._id)
  .out('KNOWS')
  .values();
```

---

## Native Database Classes

The main class for working with CongraphDB databases.

### Constructor

```typescript
new Database(
  databasePath?: string,
  bufferManagerSize?: number,
  enableCompression?: boolean,
  readOnly?: boolean,
  maxDBSize?: number,
  autoCheckpoint?: boolean,
  checkpointThreshold?: number,
  throwOnWalReplayFailure?: boolean,
  enableChecksums?: boolean
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `databasePath` | `string` | `":memory:"` | Path to database file |
| `bufferManagerSize` | `number` | `268435456` | Buffer pool size in bytes (256MB) |
| `enableCompression` | `boolean` | `false` | Enable Snappy compression |
| `readOnly` | `boolean` | `false` | Open in read-only mode |
| `maxDBSize` | `number` | `1.099511627776e+12` | Maximum database size in bytes (1TB) |
| `autoCheckpoint` | `boolean` | `true` | Auto-checkpoint WAL |
| `checkpointThreshold` | `number` | `1000000` | Checkpoint after N operations |
| `throwOnWalReplayFailure` | `boolean` | `true` | Throw error if WAL replay fails |
| `enableChecksums` | `boolean` | `true` | Enable data checksums |

**Example:**

```javascript
const db = new Database('./my-graph.cgraph', {
  bufferManagerSize: 512 * 1024 * 1024,  // 512MB
  enableCompression: true
});
```

### Methods

#### `init()`

Initialize the database. Must be called before any operations.

```javascript
db.init();
```

#### `createConnection()`

Create a new connection to the database.

```javascript
const conn = db.createConnection();
```

**Returns:** `Connection`

#### `checkpoint()`

Force a checkpoint of the write-ahead log.

```javascript
db.checkpoint();
```

#### `close()`

Close the database and release all resources.

```javascript
db.close();
```

#### `getVersion()`

Get the CongraphDB version string.

```javascript
const version = Database.getVersion();
console.log(version);  // "0.1.6"
```

**Returns:** `string`

#### `getStorageVersion()`

Get the storage format version.

```javascript
const storageVersion = Database.getStorageVersion();
console.log(storageVersion);  // 1
```

**Returns:** `number`

## Connection

A connection to the database for executing queries.

### Methods

#### `query(query: string, params?: object): Promise<QueryResult>`

Execute a query asynchronously.

```javascript
const result = await conn.query(
  'MATCH (u:User {name: $name}) RETURN u',
  { name: 'Alice' }
);
```

**Parameters:**
- `query` — Cypher query string
- `params` — Optional parameters object

**Returns:** `Promise<QueryResult>`

#### `querySync(query: string, params?: object): QueryResult`

Execute a query synchronously.

```javascript
const result = conn.querySync(
  'MATCH (u:User) RETURN COUNT(*) AS count'
);
```

**Parameters:**
- `query` — Cypher query string
- `params` — Optional parameters object

**Returns:** `QueryResult`

#### `beginTransaction()`

Begin a new transaction.

```javascript
conn.beginTransaction();
```

#### `commit()`

Commit the current transaction.

```javascript
conn.commit();
```

#### `rollback()`

Rollback the current transaction.

```javascript
conn.rollback();
```

#### `inTransaction(): boolean`

Check if currently in a transaction.

```javascript
if (conn.inTransaction()) {
  console.log('Transaction in progress');
}
```

**Returns:** `boolean`

## QueryResult

Result from executing a query.

### Methods

#### `getAll(): Array<object>`

Get all result rows as an array.

```javascript
const rows = result.getAll();
for (const row of rows) {
  console.log(row);
}
```

**Returns:** `Array<object>`

#### `getNext(): object | null`

Get the next result row, or `null` if no more rows.

```javascript
while (result.hasMore()) {
  const row = result.getNext();
  console.log(row);
}
```

**Returns:** `object | null`

#### `hasMore(): boolean`

Check if there are more rows to read.

```javascript
if (result.hasMore()) {
  const row = result.getNext();
}
```

**Returns:** `boolean`

#### `close()`

Close the result and release resources.

```javascript
result.close();
```

#### `getColumnNames(): Array<string>`

Get the column names of the result.

```javascript
const columns = result.getColumnNames();
console.log(columns);  // ['u.name', 'u.age']
```

**Returns:** `Array<string>`

#### `getColumnDataTypes(): Array<string>`

Get the column data types.

```javascript
| `getColumnDataTypes(): Array<string>` | Get the column data types. |
| `statistics: object` | Get query execution statistics (v0.1.6+). |

#### `statistics`

Contains performance metrics for the query execution.

```javascript
console.log(result.statistics);
// {
//   query: string,
//   execution_time_ms: number,
//   row_count: number,
//   query_type: string
// }
```

## Usage Examples

### Basic Query

```javascript
const { Database } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
db.init();

const conn = db.createConnection();
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name, u.age
  ORDER BY u.age DESC
  LIMIT 10
`);

for (const row of result.getAll()) {
  console.log(`${row['u.name']}: ${row['u.age']}`);
}

result.close();
conn.close();
db.close();
```

### With Parameters

```javascript
const result = await conn.query(`
  MATCH (u:User {name: $name})
  RETURN u
`, { name: 'Alice' });
```

### Transaction

```javascript
const conn = db.createConnection();
conn.beginTransaction();

try {
  await conn.query(`CREATE (u:User {name: 'Alice', age: 30})`);
  await conn.query(`CREATE (u:User {name: 'Bob', age: 25})`);
  conn.commit();
} catch (error) {
  conn.rollback();
  throw error;
}
```

### Streaming Results

```javascript
const result = await conn.query(`
  MATCH (u:User)
  RETURN u.name
`);

while (result.hasMore()) {
  const row = result.getNext();
  console.log(row['u.name']);
}

result.close();
```

## Type Definitions

```typescript
interface DatabaseOptions {
  databasePath?: string;
  bufferManagerSize?: number;
  enableCompression?: boolean;
  readOnly?: boolean;
  maxDBSize?: number;
  autoCheckpoint?: boolean;
  checkpointThreshold?: number;
  throwOnWalReplayFailure?: boolean;
  enableChecksums?: boolean;
}

interface Connection {
  query(query: string, params?: object): Promise<QueryResult>;
  querySync(query: string, params?: object): QueryResult;
  beginTransaction(): void;
  commit(): void;
  rollback(): void;
  inTransaction(): boolean;
}

interface QueryResult {
  getAll(): Array<object>;
  getNext(): object | null;
  hasMore(): boolean;
  close(): void;
  getColumnNames(): Array<string>;
  getColumnDataTypes(): Array<string>;
  readonly statistics: {
    readonly query: string;
    readonly execution_time_ms: number;
    readonly row_count: number;
    readonly query_type: string;
  };
}
```

## See Also

- [JavaScript API Reference](javascript-api.md) — CongraphDBAPI, Navigator, Pattern matching
- [Cypher Reference](cypher.md) — Query language syntax
- [Choosing Your Query Interface](../guide/choosing-interface.md) — Decision guide
- [Transactions](../guide/transactions.md) — Using transactions
