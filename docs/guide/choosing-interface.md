# Choosing Your Query Interface

CongraphDB provides **three query interfaces**, each optimized for different use cases. This guide helps you choose the right one for your needs.

## Quick Decision Tree

```
What are you trying to do?

├─ Simple CRUD (create, read, update, delete nodes/edges)
│  └─ Use: JavaScript API (CongraphDBAPI)
│     → Fastest to write, best TypeScript support
│
├─ Multi-hop graph traversal (friends of friends)
│  └─ Use: Navigator API
│     → Fluent chaining, clean syntax, LevelGraph-compatible
│
├─ Complex analytics or aggregations
│  └─ Use: Cypher Query Language
│     → Most expressive, industry standard
│
└─ Not sure?
   └─ Start with: JavaScript API
      → Easiest to learn, switch to others when needed
```

---

## Interface Comparison

| Feature | Cypher | JavaScript API | Navigator |
|---------|--------|----------------|-----------|
| **Learning Curve** | Medium | Low | Low |
| **Type Safety** | Low | High | High |
| **CRUD Operations** | ✓ | ✓★ | ✗ |
| **Single-hop Queries** | ✓ | ✓ | ✓★ |
| **Multi-hop Traversal** | ✓★ | ✗ | ✓★ |
| **Path Finding** | ✓★ | ✗ | ✓★ |
| **Aggregations** | ✓★ | ✗ | ✗ |
| **Pattern Matching** | ✓★ | ✓ | ✓ |
| **Filtering** | ✓★ | ✓ | ✓★ |
| **IDE Support** | Low | High | High |
| **Portability** | High | Low | Low |

★ = Best in class

---

## Interface Deep Dives

### Cypher Query Language

**Best for:** Complex queries, analytics, multi-hop patterns

**Use when:**
- Writing complex graph traversals
- Using path finding algorithms
- Performing aggregations and analytics
- Migrating from Neo4j or other Cypher databases
- Writing queries that feel like SQL for graphs

**Example:**
```javascript
// Complex analytics with aggregations
const result = await conn.query(`
  MATCH (u:User)-[k:KNOWS]->(f:User)
  WITH u, COUNT(f) AS friend_count
  WHERE friend_count > 10
  RETURN u.name, friend_count
  ORDER BY friend_count DESC
`);
```

**Pros:**
- Industry standard (Neo4j, RedisGraph)
- Most expressive for complex queries
- Declarative (say what you want, not how)
- Portable across graph databases
- Powerful for analytics

**Cons:**
- String-based (no compile-time checking)
- Steeper learning curve
- Less IDE support
- Overkill for simple CRUD

---

### JavaScript API (CongraphDBAPI)

**Best for:** Simple CRUD, type safety, rapid development

**Use when:**
- Building application-specific CRUD operations
- Prefer programmatic interfaces over query strings
- Want IDE autocomplete and type safety
- Building simple node/edge operations
- Need LevelDB-style CRUD API

**Example:**
```javascript
// Type-safe CRUD operations
const alice = await api.createNode('User', {
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
});

const updated = await api.updateNode(alice._id, {
  age: 31
});

await api.deleteNode(alice._id, true);
```

**Pros:**
- Type safety with TypeScript
- Excellent IDE autocomplete
- Familiar JavaScript patterns
- Fastest for simple operations
- No query string parsing
- Transaction helper method

**Cons:**
- Not ideal for complex multi-hop queries
- More verbose for complex patterns
- Less portable than Cypher

---

### Navigator API

**Best for:** Fluent traversal, path finding, readability

**Use when:**
- Doing multi-hop graph traversals
- Want fluent chaining syntax
- Building recommendation engines
- Need path finding algorithms
- Migrating from LevelGraph

**Example:**
```javascript
// Clean, readable traversal
const friendsOfFriends = await api.nav(alice._id)
  .out('KNOWS')
  .out('KNOWS')
  .where(f => f.age > 25)
  .limit(10)
  .values();

// Path finding
const path = await api.nav(alice._id)
  .out('KNOWS')
  .to(bob._id)
  .values();
```

**Pros:**
- Clean, readable fluent syntax
- Excellent for multi-hop traversals
- Built-in path finding
- LevelGraph-compatible
- Async iteration support
- Chaining feels natural

**Cons:**
- Not for CRUD operations
- Less expressive than Cypher for complex queries
- Limited aggregation support

---

## Use Case Recommendations

### Web Applications

**Recommended:** JavaScript API for CRUD + Navigator for social features

```javascript
// Backend: CRUD with JavaScript API
const user = await api.createNode('User', userData);
const posts = await api.getNodesByLabel('Post');

// Social features: Navigator for traversal
const friends = await api.nav(userId).out('FOLLOWS').values();
const recommendations = await api.nav(userId)
  .out('FOLLOWS')
  .out('FOLLOWS')
  .limit(10)
  .values();
```

### Analytics & Reporting

**Recommended:** Cypher for complex aggregations

```javascript
// Popular content analytics
const result = await conn.query(`
  MATCH (u:User)-[:POSTED]->(p:Post)<-[:LIKED]-(liker:User)
  RETURN p.title, COUNT(liker) AS likes
  ORDER BY likes DESC
  LIMIT 10
`);

// Influencer detection
const result = await conn.query(`
  MATCH (u:User)<-[:FOLLOWS]-(follower:User)
  RETURN u.name, COUNT(follower) AS followers
  ORDER BY followers DESC
`);
```

### Real-time Applications

**Recommended:** JavaScript API for speed

```javascript
// Fast CRUD for real-time updates
await api.updateNode(sessionId, { lastSeen: Date.now() });
await api.createEdge(userId, 'ACTIVE_IN', roomId._id);
```

### Data Migration

**From Neo4j:** Use Cypher (same language)
```javascript
// Drop-in replacement for Neo4j queries
const result = await conn.query(`
  MATCH (p:Person)-[:KNOWS]->(f:Person)
  RETURN p.name, f.name
`);
```

**From LevelGraph:** Use Navigator (compatible API)
```javascript
// LevelGraph-style navigation
const results = await api.nav(startId)
  .archOut('friend')  // LevelGraph method
  .solutions();       // LevelGraph method
```

---

## Performance Considerations

### Operation Performance

| Operation | Fastest | Notes |
|-----------|---------|-------|
| Single CRUD | JavaScript API | Direct method calls |
| Multi-hop (2-3) | Navigator | Optimized traversal |
| Multi-hop (4+) | Cypher | Query optimization |
| Aggregations | Cypher | Columnar storage |
| Pattern matching | Cypher | Index usage |

### When to Switch Interfaces

You can use all three interfaces together:

```javascript
// Setup with JavaScript API
const api = new CongraphDBAPI(db);
const alice = await api.createNode('Person', {...});

// Traverse with Navigator
const friends = await api.nav(alice._id).out('KNOWS').values();

// Complex analytics with Cypher
const analytics = await api.query(`
  MATCH (p:Person)-[:KNOWS]->(f:Person)
  RETURN p.city, COUNT(f) AS friend_count
`);
```

**Switch when:**
- Your query gets complex → Switch to Cypher
- You need type safety → Switch to JavaScript API
- You're doing traversal → Switch to Navigator

---

## Migration Examples

### From SQL to CongraphDB

```sql
-- SQL: Find friends of friends
SELECT f2.name
FROM friends f1
JOIN friends f2 ON f1.friend_id = f2.user_id
WHERE f1.user_id = ?
```

```javascript
// JavaScript API: Multiple find() calls
const friends = await api.find({
  subject: userId,
  predicate: 'FRIEND',
  object: api.v('friend')
});
// Then iterate and find friends of friends...

// Navigator: Much cleaner
const fof = await api.nav(userId)
  .out('FRIEND')
  .out('FRIEND')
  .values();

// Cypher: Most like SQL
const result = await conn.query(`
  MATCH (u:User)-[:FRIEND]->(:User)-[:FRIEND]->(fof:User)
  RETURN fof.name
`);
```

### From MongoDB to CongraphDB

```javascript
// MongoDB: Embedded documents
const user = await db.collection('users').findOne({ _id: userId });
const friends = user.friends.map(id => db.collection('users').findOne({ _id: id }));

// CongraphDB: JavaScript API
const user = await api.getNode(userId);
const friendIds = await api.find({
  subject: userId,
  predicate: 'FRIEND',
  object: api.v('friend')
});
const friends = await Promise.all(
  friendIds.map(f => api.getNode(f.friend._id))
);

// CongraphDB: Navigator (cleaner)
const friends = await api.nav(userId).out('FRIEND').values();
```

---

## Summary Checklist

**Choose Cypher if:**
- [ ] Writing complex multi-hop queries
- [ ] Need aggregations or analytics
- [ ] Migrating from Neo4j
- [ ] Want portable graph queries

**Choose JavaScript API if:**
- [ ] Doing simple CRUD operations
- [ ] Want type safety with TypeScript
- [ ] Need IDE autocomplete
- [ ] Building application-specific data access
- [ ] New to graph databases

**Choose Navigator if:**
- [ ] Doing graph traversal (2+ hops)
- [ ] Want fluent chaining syntax
- [ ] Building social features
- [ ] Need path finding
- [ ] Migrating from LevelGraph

**Remember:** You can mix and match! Use each interface for its strengths.

---

## See Also

- [JavaScript API Reference](../api/javascript-api.md) - Complete API documentation
- [Cypher Reference](../api/cypher.md) - Query language syntax
- [Quick Start](quick-start.md) - Getting started with CongraphDB
- [Sample Project](https://github.com/congraph-ai/congraphdb-sample) - Example code
