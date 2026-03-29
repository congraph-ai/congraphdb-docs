# Migrating from LevelGraph

CongraphDB's **Navigator API** provides a LevelGraph-compatible interface for graph traversal. This guide helps you migrate from LevelGraph to CongraphDB.

## Quick Comparison

| Feature | LevelGraph | CongraphDB Navigator |
|---------|------------|---------------------|
| **API Style** | Fluent traversal | Fluent traversal (compatible) |
| **Storage** | LevelDB (key-value) | Native graph storage |
| **Schema** | Schema-less | Schema required |
| **Query Language** | None | Cypher (optional) |
| **Type Safety** | No | TypeScript support |

## Installation Change

### LevelGraph
```javascript
npm install level levelgraph
```

```javascript
const level = require('level');
const levelgraph = require('levelgraph');
const db = levelgraph('./my-graph');
```

### CongraphDB
```javascript
npm install congraphdb
```

```javascript
const { Database, CongraphDBAPI } = require('congraphdb');
const db = new Database('./my-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);
```

## API Compatibility

CongraphDB's Navigator API is designed to be compatible with LevelGraph. Most LevelGraph code works with minimal changes.

### Basic Traversal

#### LevelGraph
```javascript
// Put triple
db.put([{ subject: 'alice', predicate: 'friend', object: 'bob' }], (err) => {
  if (err) throw err;
});

// Get triple
db.get({ subject: 'alice', predicate: 'friend', object: 'bob' }, (err, node) => {
  console.log(node);
});
```

#### CongraphDB Navigator
```javascript
// Create nodes and edge
const alice = await api.createNode('User', { name: 'Alice' });
const bob = await api.createNode('User', { name: 'Bob' });
await api.createEdge(alice._id, 'FRIEND', bob._id);

// Traverse with Navigator
const friends = await api.nav(alice._id)
  .out('FRIEND')
  .values();
```

## Method Mapping

### LevelGraph → Navigator

| LevelGraph Method | Navigator Method | Notes |
|-------------------|------------------|-------|
| `get({ triple })` | `nav().out().values()` | Different API style |
| `put({ triple })` | `createEdge()` | Must create nodes first |
| `del({ triple })` | `deleteEdge()` | Uses edge ID |
| `nav(source).archOut(pred)` | `nav(source).out(pred)` | Compatible alias |
| `nav(source).archIn(pred)` | `nav(source).in(pred)` | Compatible alias |
| `solutions()` | `values()` | Compatible alias |
| `solutionsSync()` | `valuesSync()` | Compatible alias |

### Navigator-Specific Methods

CongraphDB Navigator adds additional methods not in LevelGraph:

```javascript
// New methods
await api.nav(alice._id)
  .both('FRIEND')      // Bidirectional traversal
  .where(f => f.age > 25)  // JavaScript function filtering
  .limit(10)           // Limit results
  .paths()             // Get full paths instead of just nodes
  .to(targetId)        // Path finding
  .count()             // Count without retrieving
  .values();
```

## Schema Requirements

### LevelGraph (Schema-less)

```javascript
// LevelDB stores any JSON automatically
db.put([
  { subject: 'alice', predicate: 'friend', object: 'bob', since: 2020 },
  { subject: 'bob', predicate: 'friend', object: 'charlie' }
], callback);
```

### CongraphDB (Schema Required)

```javascript
// Must define schema first
const conn = db.createConnection();

await conn.query(`
  CREATE NODE TABLE User (
    id STRING,
    name STRING,
    age INT64,
    PRIMARY KEY (id)
  )
`);

await conn.query(`
  CREATE REL TABLE FRIEND (
    FROM User TO User,
    since INT64
  )
`);

// Then create data
const api = new CongraphDBAPI(db);
const alice = await api.createNode('User', { id: 'alice', name: 'Alice', age: 30 });
const bob = await api.createNode('User', { id: 'bob', name: 'Bob', age: 25 });
await api.createEdge(alice._id, 'FRIEND', bob._id, { since: 2020 });
```

## Migration Examples

### Example 1: Social Network

#### LevelGraph
```javascript
const level = require('level');
const levelgraph = require('levelgraph');
const db = levelgraph(level('./social'));

// Add friends
db.put([
  { subject: 'alice', predicate: 'friend', object: 'bob' },
  { subject: 'alice', predicate: 'friend', object: 'charlie' }
], (err) => {
  if (err) throw err;

  // Find Alice's friends
  db.nav('alice').archOut('friend').solutions((err, friends) => {
    console.log('Friends:', friends);
  });
});
```

#### CongraphDB Navigator
```javascript
const { Database, CongraphDBAPI } = require('congraphdb');

const db = new Database('./social.cgraph');
await db.init();

// Define schema (first time only)
const conn = db.createConnection();
await conn.query(`
  CREATE NODE TABLE User (id STRING, name STRING, PRIMARY KEY (id))
`);
await conn.query(`
  CREATE REL TABLE FRIEND (FROM User TO User)
`);

const api = new CongraphDBAPI(db);

// Create users
const alice = await api.createNode('User', { id: 'alice', name: 'Alice' });
const bob = await api.createNode('User', { id: 'bob', name: 'Bob' });
const charlie = await api.createNode('User', { id: 'charlie', name: 'Charlie' });

// Add friends
await api.createEdge(alice._id, 'FRIEND', bob._id);
await api.createEdge(alice._id, 'FRIEND', charlie._id);

// Find Alice's friends (LevelGraph compatible)
const friends = await api.nav(alice._id)
  .archOut('FRIEND')    // LevelGraph method
  .solutions();         // LevelGraph method

console.log('Friends:', friends);
```

### Example 2: Multi-hop Traversal

#### LevelGraph
```javascript
// Friends of friends
db.nav('alice').archOut('friend').archOut('friend').solutions((err, fof) => {
  console.log('Friends of friends:', fof);
});
```

#### CongraphDB Navigator
```javascript
// Same API works
const fof = await api.nav(alice._id)
  .archOut('friend')
  .archOut('friend')
  .solutions();

// Or use the more idiomatic out()
const fof = await api.nav(alice._id)
  .out('friend')
  .out('friend')
  .values();
```

### Example 3: Filtering

#### LevelGraph
```javascript
// LevelGraph filtering (limited)
db.nav('alice').archOut('friend').solutions((err, friends) => {
  const youngFriends = friends.filter(f => f.age < 30);
  console.log('Young friends:', youngFriends);
});
```

#### CongraphDB Navigator
```javascript
// Built-in filtering (more efficient)
const youngFriends = await api.nav(alice._id)
  .out('FRIEND')
  .where(f => f.age < 30)
  .values();

// Or with Cypher-style string
const youngFriends = await api.nav(alice._id)
  .out('FRIEND')
  .where('age < 30')
  .values();
```

### Example 4: Bidirectional Traversal

#### LevelGraph
```javascript
// LevelGraph requires separate calls for in/out
db.nav('alice').archOut('friend').solutions((err, out) => {
  db.nav('alice').archIn('friend').solutions((err, in) => {
    const all = [...out, ...in];
    console.log('All connections:', all);
  });
});
```

#### CongraphDB Navigator
```javascript
// Built-in both() method
const all = await api.nav(alice._id)
  .both('FRIEND')
  .values();
```

### Example 5: Path Finding

#### LevelGraph
```javascript
// LevelGraph doesn't have built-in path finding
// Would require manual implementation
```

#### CongraphDB Navigator
```javascript
// Built-in path finding
const path = await api.nav(alice._id)
  .out('FRIEND')
  .to(bob._id)
  .values();
```

## Advanced Patterns

### Pattern 1: Recommendation Engine

#### LevelGraph
```javascript
// Find people followed by people I follow
db.nav('me').archOut('follows').archOut('follows').solutions((err, fof) => {
  // Filter out people I already follow
  db.nav('me').archOut('follows').solutions((err, following) => {
    const followingIds = new Set(following.map(f => f.id));
    const recommendations = fof.filter(f => !followingIds.has(f.id));
    console.log('Recommendations:', recommendations);
  });
});
```

#### CongraphDB Navigator
```javascript
// More efficient with built-in filtering
const myFollowing = await api.nav('me')
  .out('FOLLOWS')
  .values();
const followingIds = new Set(myFollowing.map(f => f._id));

const recommendations = await api.nav('me')
  .out('FOLLOWS')
  .out('FOLLOWS')
  .where(f => !followingIds.has(f._id))
  .values();
```

### Pattern 2: Graph Analytics

#### LevelGraph
```javascript
// Count friends (manual)
db.nav('alice').archOut('friend').solutions((err, friends) => {
  console.log('Friend count:', friends.length);
});
```

#### CongraphDB Navigator
```javascript
// Built-in count (more efficient)
const count = await api.nav('alice._id)
  .out('FRIEND')
  .count();

console.log('Friend count:', count);
```

### Pattern 3: Async Iteration

#### LevelGraph (Callback-based)
```javascript
// Manual iteration
db.nav('alice').archOut('friend').solutions((err, friends) => {
  friends.forEach(friend => {
    console.log('Friend:', friend);
  });
});
```

#### CongraphDB Navigator (Async Iterator)
```javascript
// Modern async iteration
for await (const friend of api.nav('alice._id).out('FRIEND')) {
  console.log('Friend:', friend);
}
```

## Data Model Migration

### LevelGraph Triple Model

```javascript
// LevelGraph: Subject → Predicate → Object
{
  subject: 'alice',
  predicate: 'friend',
  object: 'bob',
  since: 2020
}
```

### CongraphDB Graph Model

```javascript
// CongraphDB: Nodes and Edges

// Nodes
{ _id: 'alice-id', name: 'Alice', ... }
{ _id: 'bob-id', name: 'Bob', ... }

// Edge
{
  _id: 'edge-id',
  _type: 'FRIEND',
  _from: 'alice-id',
  _to: 'bob-id',
  since: 2020
}
```

### Migration Strategy

1. **Extract Unique Entities**
   ```javascript
   // From LevelGraph triples, extract unique subjects and objects
   const entities = new Set();
   triples.forEach(t => {
     entities.add(t.subject);
     entities.add(t.object);
   });
   ```

2. **Create Nodes**
   ```javascript
   for (const entity of entities) {
     await api.createNode('Entity', { id: entity });
   }
   ```

3. **Create Edges**
   ```javascript
   for (const triple of triples) {
     const fromNode = await api.find({ subject: triple.subject, predicate: api.v('n') });
     const toNode = await api.find({ subject: triple.object, predicate: api.v('n') });
     await api.createEdge(fromNode[0].n._id, triple.predicate, toNode[0].n._id);
   }
   ```

## Callback to Promise Migration

### LevelGraph (Callback-based)
```javascript
db.get({ subject: 'alice', predicate: 'friend' }, (err, result) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log('Result:', result);
});
```

### CongraphDB (Promise-based)
```javascript
try {
  const result = await api.find({
    subject: alice._id,
    predicate: 'FRIEND',
    object: api.v('friend')
  });
  console.log('Result:', result);
} catch (err) {
  console.error(err);
}
```

### Using Promisify (Migration Helper)

```javascript
const { promisify } = require('util');

// If you need to gradually migrate
const dbGet = promisify(db.get);
const dbPut = promisify(db.put);
const dbNav = promisify(db.nav);

async function migrate() {
  const result = await dbGet({ subject: 'alice' });
  return result;
}
```

## Performance Comparison

| Operation | LevelGraph | CongraphDB Navigator |
|-----------|------------|---------------------|
| **Single hop** | Fast | Faster (native graph storage) |
| **Multi-hop** | Multiple lookups | Optimized traversal |
| **Filtering** | In-memory | Database-level filtering |
| **Counting** | Load all then count | Built-in efficient count |
| **Path finding** | Manual implementation | Built-in algorithms |

## Key Differences

### 1. Storage Model

**LevelGraph:**
- Key-value store (LevelDB)
- Triples stored as keys
- Manual indexing required

**CongraphDB:**
- Native graph storage
- Optimized for graph operations
- Built-in relationship indexing

### 2. Query Capabilities

**LevelGraph:**
- Navigator API only
- No native query language
- Manual implementation for complex queries

**CongraphDB:**
- Navigator API (LevelGraph-compatible)
- Cypher query language
- Built-in path finding and analytics

### 3. Type Safety

**LevelGraph:**
- No TypeScript support
- Schema-less
- Runtime errors

**CongraphDB:**
- TypeScript definitions included
- Schema required
- Compile-time type checking

### 4. Transaction Support

**LevelGraph:**
- LevelDB batch operations
- No ACID guarantees across triples

**CongraphDB:**
- Full ACID transactions
- Write-ahead logging
- Serializable isolation

## Migration Checklist

- [ ] **Step 1: Analyze Data Model**
  - [ ] Identify all unique subjects and objects (become nodes)
  - [ ] Identify all predicates (become relationship types)
  - [ ] Identify properties on triples

- [ ] **Step 2: Define Schema**
  - [ ] Create NODE TABLE definitions
  - [ ] Create REL TABLE definitions
  - [ ] Define PRIMARY KEYs

- [ ] **Step 3: Migrate Data**
  - [ ] Extract entities from triples
  - [ ] Create nodes
  - [ ] Create edges
  - [ ] Preserve edge properties

- [ ] **Step 4: Update Code**
  - [ ] Replace `db.put()` with `createNode()`/`createEdge()`
  - [ ] Replace callbacks with promises/async-await
  - [ ] Update navigator calls
  - [ ] Remove manual filtering logic

- [ ] **Step 5: Add CongraphDB Features**
  - [ ] Use Cypher for complex queries
  - [ ] Use built-in path finding
  - [ ] Use transactions where needed
  - [ ] Add TypeScript types

## Common Issues and Solutions

### Issue 1: Callback Hell

**LevelGraph code:**
```javascript
db.nav('alice').archOut('friend').solutions((err, friends) => {
  if (err) return next(err);
  db.nav('bob').archOut('friend').solutions((err2, friends2) => {
    if (err2) return next(err2);
    const all = [...friends, ...friends2];
    res.json(all);
  });
});
```

**CongraphDB solution:**
```javascript
const [friends, friends2] = await Promise.all([
  api.nav('alice').out('FRIEND').values(),
  api.nav('bob').out('FRIEND').values()
]);
const all = [...friends, ...friends2];
```

### Issue 2: Duplicate Results

**LevelGraph:**
```javascript
// May return duplicates
db.nav('alice').archOut('friend').archOut('friend').solutions((err, fof) => {
  console.log(fof.length); // May include original friends
});
```

**CongraphDB Navigator:**
```javascript
// Use DISTINCT in Cypher or manual deduplication
const fof = await api.nav('alice._id)
  .out('FRIEND')
  .out('FRIEND')
  .values();

// Or use Cypher for DISTINCT
const result = await conn.query(`
  MATCH (a:User {id: 'alice'})-[:FRIEND]->()->[:FRIEND]->(fof:User)
  RETURN DISTINCT fof
`);
```

## Tips for Successful Migration

1. **Start Small**
   - Migrate one query at a time
   - Use both databases during transition
   - Compare results to verify correctness

2. **Leverage Compatibility**
   - Use `archOut()`/`archIn()` initially
   - Switch to `out()`/`in()` gradually
   - Use `solutions()` for familiarity

3. **Adopt New Features**
   - Use `both()` for bidirectional traversal
   - Use `where()` for filtering
   - Use Cypher for complex analytics

4. **Add Type Safety**
   - Use TypeScript definitions
   - Define interfaces for your nodes
   - Get compile-time checking

## See Also

- [Navigator API Reference](../api/javascript-api.md#navigator) - Complete Navigator documentation
- [Choosing Your Query Interface](choosing-interface.md) - When to use Navigator vs Cypher
- [JavaScript API Examples](https://github.com/congraph-ai/congraphdb-sdk) - Example code
