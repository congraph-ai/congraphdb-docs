# JavaScript API Reference

CongraphDB provides a **JavaScript-native API** as an alternative to Cypher for developers who prefer a programmatic interface. This API is particularly useful for:

- Simple CRUD operations on nodes and edges
- Application-specific data access patterns
- Developers who prefer method calls over query strings
- LevelGraph users seeking a familiar API
- Type safety with TypeScript

## Quick Start

```javascript
const { Database, CongraphDBAPI } = require('congraphdb');

// Initialize
const db = new Database('./my-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);

// Create nodes
const alice = await api.createNode('User', { name: 'Alice', age: 30 });
const bob = await api.createNode('User', { name: 'Bob', age: 25 });

// Create relationships
await api.createEdge(alice._id, 'KNOWS', bob._id, { since: 2020 });

// Query with pattern matching
const friends = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
});

// Fluent traversal API
const friendsOfFriends = await api.nav(alice._id)
  .out('KNOWS')
  .out('KNOWS')
  .values();

// Cleanup
await api.close();
await db.close();
```

---

## CongraphDBAPI

The main API class providing access to all graph operations.

### Constructor

```typescript
new CongraphDBAPI(dbOrConnection: Database | Connection)
```

Creates a new CongraphDBAPI instance. Accepts either a Database or Connection object.

```javascript
const api = new CongraphDBAPI(db);
// or
const api = new CongraphDBAPI(connection);
```

### Node Operations

#### createNode(label, properties)

Create a new node with the given label and properties.

```javascript
const node = await api.createNode('Person', {
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
});
// Returns: { _id: '...', name: 'Alice', age: 30, email: '...' }
```

#### getNode(id)

Get a node by its ID.

```javascript
const node = await api.getNode('node-id-here');
// Returns the node object or null if not found
```

#### getNodesByLabel(label)

Get all nodes with a specific label.

```javascript
const users = await api.getNodesByLabel('User');
// Returns: Array of node objects
```

#### updateNode(id, properties)

Update a node's properties.

```javascript
const updated = await api.updateNode('node-id', {
  age: 31,
  lastSeen: Date.now()
});
// Returns the updated node
```

#### deleteNode(id, detach)

Delete a node.

```javascript
// Delete node (fails if it has relationships)
await api.deleteNode('node-id');

// Delete node and all relationships
await api.deleteNode('node-id', true);
```

### Edge Operations

#### createEdge(fromId, relType, toId, properties)

Create a new relationship between nodes.

```javascript
const edge = await api.createEdge(
  'alice-node-id',  // from node
  'KNOWS',          // relationship type
  'bob-node-id',    // to node
  { since: 2020 }   // edge properties (optional)
);
// Returns: { _id: '...', _type: 'KNOWS', _from: '...', _to: '...', since: 2020 }
```

#### getEdge(id)

Get an edge by its ID.

```javascript
const edge = await api.getEdge('edge-id-here');
```

#### getEdges(options)

Get edges with optional filtering.

```javascript
// All edges from a node
const outgoing = await api.getEdges({ from: 'node-id' });

// All edges to a node
const incoming = await api.getEdges({ to: 'node-id' });

// All edges of a specific type
const knowsEdges = await api.getEdges({ type: 'KNOWS' });

// Combined filters
const results = await api.getEdges({
  from: 'node-id',
  type: 'KNOWS'
});
```

#### updateEdge(id, properties)

Update an edge's properties.

```javascript
const updated = await api.updateEdge('edge-id', {
  since: 2021,
  strength: 5
});
```

#### deleteEdge(id)

Delete an edge.

```javascript
await api.deleteEdge('edge-id');
```

### Pattern Matching

#### find(pattern, options)

Execute a pattern matching query.

```javascript
// Simple pattern
const friends = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
});
// Returns: [{ friend: { name: 'Bob', ... } }, ...]

// With WHERE filter
const results = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
}, {
  where: 'friend.age > 25'
});

// With multiple variables
const results = await api.find({
  subject: api.v('person'),
  predicate: 'KNOWS',
  object: api.v('friend')
});
```

#### v(name)

Create a variable for pattern matching results.

```javascript
const friendVar = api.v('friend');
const results = await api.find({
  subject: alice._id,
  predicate: 'KNOWS',
  object: friendVar
});
```

### Navigation

#### nav(startId)

Create a Navigator for fluent graph traversal.

```javascript
const navigator = api.nav('node-id');
```

See [Navigator](#navigator) section below for full traversal API.

### Transactions

#### transaction(fn)

Execute operations in a transaction.

```javascript
await api.transaction(async (txApi) => {
  const alice = await txApi.createNode('Person', { name: 'Alice' });
  const bob = await txApi.createNode('Person', { name: 'Bob' });
  await txApi.createEdge(alice._id, 'KNOWS', bob._id);
  // All operations commit if no error is thrown
});
```

### Raw Queries

#### query(cypher)

Execute a raw Cypher query.

```javascript
const result = await api.query(`
  MATCH (p:Person)-[:KNOWS]->(f:Person)
  RETURN p.name, f.name
`);
const rows = await result.getAll();
```

### Utilities

#### close()

Close the API and cleanup resources.

```javascript
await api.close();
```

---

## Navigator

Fluent graph traversal API (LevelGraph-compatible).

### Creating a Navigator

```javascript
const nav = api.nav('starting-node-id');
```

### Traversal Methods

#### out(relType)

Traverse outgoing relationships.

```javascript
const friends = await api.nav(alice._id)
  .out('KNOWS')
  .values();
```

#### in(relType)

Traverse incoming relationships.

```javascript
const followers = await api.nav(alice._id)
  .in('KNOWS')
  .values();
```

#### both(relType)

Traverse relationships in both directions.

```javascript
const connections = await api.nav(alice._id)
  .both('KNOWS')
  .values();
```

### Chaining Traversals

```javascript
// Two-hop traversal
const friendsOfFriends = await api.nav(alice._id)
  .out('KNOWS')
  .out('KNOWS')
  .values();

// Three-hop traversal
const threeHop = await api.nav(alice._id)
  .out('KNOWS')
  .out('KNOWS')
  .out('KNOWS')
  .values();
```

### Filtering

#### where(condition)

Filter results by condition.

```javascript
// String condition (Cypher-style)
const nycFriends = await api.nav(alice._id)
  .out('KNOWS')
  .where('city = "NYC"')
  .values();

// Function condition (JavaScript)
const youngFriends = await api.nav(alice._id)
  .out('KNOWS')
  .where(f => f.age < 30)
  .values();
```

#### limit(n)

Limit the number of results.

```javascript
const firstFive = await api.nav(alice._id)
  .out('KNOWS')
  .limit(5)
  .values();
```

### Path Finding

#### to(targetId)

Find the shortest path to a target node.

```javascript
const path = await api.nav(alice._id)
  .out('KNOWS')
  .to(bob._id)
  .values();
```

### Getting Results

#### values()

Get matching nodes as an array.

```javascript
const nodes = await api.nav(alice._id)
  .out('KNOWS')
  .values();
```

#### paths()

Get full paths (including intermediate nodes and edges).

```javascript
const paths = await api.nav(alice._id)
  .out('KNOWS')
  .out('KNOWS')
  .paths();
```

#### count()

Count matching nodes.

```javascript
const count = await api.nav(alice._id)
  .out('KNOWS')
  .count();
```

### Synchronous Methods

All traversal methods have synchronous variants:

```javascript
const nodes = api.nav(alice._id)
  .out('KNOWS')
  .valuesSync();

const paths = api.nav(alice._id)
  .out('KNOWS')
  .pathsSync();

const count = api.nav(alice._id)
  .out('KNOWS')
  .countSync();
```

### Async Iteration

Navigate using `for await...of`:

```javascript
for await (const friend of api.nav(alice._id).out('KNOWS')) {
  console.log(friend.name);
}
```

### LevelGraph Compatibility

The Navigator API provides LevelGraph-compatible aliases:

```javascript
// LevelGraph-style methods
const results = await api.nav(alice._id)
  .archOut('KNOWS')  // Alias for .out()
  .solutions();      // Alias for .values()
```

---

## Pattern

Represents a graph pattern for matching queries.

### Constructor

```javascript
const pattern = new Pattern({
  subject: alice._id,
  predicate: 'KNOWS',
  object: api.v('friend')
});
```

### Using Patterns

```javascript
const pattern = new Pattern({
  subject: api.v('person'),
  predicate: 'KNOWS',
  object: api.v('friend')
});

const results = await api.find(pattern);
```

---

## Variable

Represents a variable in pattern matching.

### Creating Variables

```javascript
const friendVar = api.v('friend');
const personVar = api.v('person');
```

### Using Variables

```javascript
const results = await api.find({
  subject: api.v('person'),
  predicate: 'KNOWS',
  object: api.v('friend')
});

// Results are keyed by variable name
results[0].person; // First matching person
results[0].friend; // First matching friend
```

---

## Type Definitions

```typescript
class CongraphDBAPI {
  constructor(dbOrConnection: Database | Connection)

  // Node operations
  createNode(label: string, properties: object): Promise<Node>
  getNode(id: string): Promise<Node | null>
  getNodesByLabel(label: string): Promise<Node[]>
  updateNode(id: string, properties: object): Promise<Node>
  deleteNode(id: string, detach?: boolean): Promise<boolean>

  // Edge operations
  createEdge(fromId: string, relType: string, toId: string, properties?: object): Promise<Edge>
  getEdge(id: string): Promise<Edge | null>
  getEdges(options?: {from?: string, to?: string, type?: string}): Promise<Edge[]>
  updateEdge(id: string, properties: object): Promise<Edge>
  deleteEdge(id: string): Promise<boolean>

  // Pattern matching
  find(pattern: Pattern | object, options?: object): Promise<any[]>
  v(name: string): Variable
  nav(startId: string): Navigator

  // Transactions
  transaction(fn: (api: CongraphDBAPI) => Promise<T>): Promise<T>

  // Raw queries
  query(cypher: string): Promise<QueryResult>

  // Utilities
  close(): Promise<void>
}

class Navigator {
  // Traversal
  out(relType: string): Navigator
  in(relType: string): Navigator
  both(relType: string): Navigator

  // Filtering
  where(condition: string | Function): Navigator
  limit(n: number): Navigator

  // Path finding
  to(targetId: string): Navigator

  // Results
  values(): Promise<Node[]>
  paths(): Promise<Path[]>
  count(): Promise<number>

  // Synchronous variants
  valuesSync(): Node[]
  pathsSync(): Path[]
  countSync(): number

  // LevelGraph compatibility
  archOut(relType: string): Navigator
  archIn(relType: string): Navigator
  solutions(): Promise<Node[]>

  // Async iteration
  [Symbol.asyncIterator](): AsyncIterator<Node>
}

class Pattern {
  constructor(pattern: object)
}

class Variable {
  constructor(name: string)
}
```

---

## See Also

- [Choosing Your Query Interface](../guide/choosing-interface.md) - Decision guide for Cypher vs JavaScript API vs Navigator
- [JavaScript Native Bindings](javascript.md) - Database, Connection, and QueryResult reference
- [Cypher Reference](cypher.md) - Query language syntax
