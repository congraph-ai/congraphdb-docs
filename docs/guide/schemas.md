# Schemas

In CongraphDB, you define your graph schema using **node tables** and **relationship tables**.

## Node Tables

Node tables define the structure of your nodes (entities).

### Syntax

```cypher
CREATE NODE TABLE TableName(
  property_name DATA_TYPE,
  ...
  PRIMARY KEY (property_name)
)
```

### Example

```javascript
await conn.query(`
  CREATE NODE TABLE User(
    name STRING,
    age INT64,
    email STRING,
    created_at INT64,
    PRIMARY KEY (name)
  )
`);
```

### Supported Data Types

| Type | Description | Example |
|------|-------------|---------|
| `STRING` | Text string | `"hello"` |
| `INT64` | 64-bit integer | `42` |
| `FLOAT64` | 64-bit float | `3.14` |
| `BOOL` | Boolean | `true`, `false` |
| `DATE` | Date (days since epoch) | `DATE '2024-01-01'` |
| `TIMESTAMP` | Timestamp (ms since epoch) | `TIMESTAMP '2024-01-01T00:00:00'` |
| `INT64[]` | Array of integers | `[1, 2, 3]` |
| `FLOAT64[]` | Array of floats | `[1.0, 2.5, 3.14]` |
| `STRING[]` | Array of strings | `["a", "b", "c"]` |
| `FLOAT_VECTOR[n]` | Fixed-size vector (for embeddings) | `FLOAT_VECTOR[128]` |

## Relationship Tables

Relationship tables define the structure of relationships (edges) between nodes.

### Syntax

```cypher
CREATE REL TABLE RelName(
  FROM FromNodeTable TO ToNodeTable,
  property_name DATA_TYPE,
  ...
)
```

### Example

```javascript
await conn.query(`
  CREATE REL TABLE Knows(
    FROM User TO User,
    since INT64,
    strength FLOAT64
  )
`);
```

### Multiple Relationship Types

```javascript
// User follows another user
await conn.query(`
  CREATE REL TABLE Follows(FROM User TO User, since INT64)
`);

// User belongs to a group
await conn.query(`
  CREATE REL TABLE MemberOf(FROM User TO Group, joined_at INT64)
`);

// Document references another document
await conn.query(`
  CREATE REL TABLE References(FROM Document TO Document)
`);
```

## Complete Example

```javascript
const { Database } = require('congraphdb');

async function main() {
  const db = new Database('./social-graph.cgraph');
  db.init();
  const conn = db.createConnection();

  // Create node tables
  await conn.query(`
    CREATE NODE TABLE User(
      username STRING,
      display_name STRING,
      bio STRING,
      created_at INT64,
      PRIMARY KEY (username)
    )
  `);

  await conn.query(`
    CREATE NODE TABLE Post(
      id INT64,
      content STRING,
      created_at INT64,
      PRIMARY KEY (id)
    )
  `);

  // Create relationship tables
  await conn.query(`
    CREATE REL TABLE Follows(FROM User TO User, since INT64)
  `);

  await conn.query(`
    CREATE REL TABLE Authored(FROM User TO Post, published_at INT64)
  `);

  await conn.query(`
    CREATE REL TABLE Likes(FROM User TO Post, liked_at INT64)
  `);

  db.close();
}

main().catch(console.error);
```

## Schema Validation

CongraphDB enforces schema rules:

- **Primary keys** are required for node tables
- **Relationships** must reference valid node tables
- **Data types** are enforced on insert/update

## Next Steps

- [Queries](queries.md) — Learn how to query your schema
- [Transactions](transactions.md) — Work with transactions
