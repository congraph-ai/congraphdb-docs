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

## Dynamic Property Creation

While CongraphDB uses a schema-based columnar engine for performance, it provides **schemaless flexibility** through dynamic property creation.

If you attempt to `SET` a property that was not defined in the initial `CREATE NODE TABLE` or `CREATE REL TABLE` statement, CongraphDB will **automatically add a new column** to the table to accommodate the new data.

### Example

```javascript
// Table created with only 'name' and 'age'
await conn.query(`
  CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))
`);

// Setting a non-existent property 'city'
await conn.query(`
  MATCH (u:User {name: 'Alice'})
  SET u.city = 'New York', u.occupation = 'Engineer'
`);

// The 'city' and 'occupation' columns are created automatically.
// They will be available for all future nodes in the 'User' table.
```

### Key Considerations

1.  **Type Inference**: The data type of the new column is inferred from the first value assigned to it.
2.  **Performance**: Frequent dynamic column creation can lead to schema churn. It is recommended to define known properties upfront in the schema.
3.  **Nullability**: Dynamic columns are always nullable. Existing rows will have `NULL` values for the new property.

## JavaScript Schema API _(v0.1.7+)_

CongraphDB provides a **JavaScript-native Schema API** for defining and managing database schema without writing raw Cypher DDL queries. This API is particularly useful for:

- Type-safe schema creation in JavaScript/TypeScript
- Schema migrations and version control
- Programmatic schema management
- Developers who prefer code over query strings for DDL operations

### Quick Start with Schema API

```javascript
const { Database, CongraphDBAPI } = require('congraphdb');

// Initialize
const db = new Database('./my-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);

// Create node tables
await api.schema.createNodeTable('User', {
  properties: {
    id: 'string',
    name: 'string',
    age: 'int64',
    email: 'string'
  },
  primaryKey: 'id'
});

await api.schema.createNodeTable('Post', {
  properties: {
    id: 'string',
    title: 'string',
    content: 'string',
    createdAt: 'int64'
  },
  primaryKey: 'id'
});

// Create relationship tables
await api.schema.createRelTable('AUTHORED', {
  from: 'User',
  to: 'Post',
  properties: {
    createdAt: 'int64'
  }
});

await api.schema.createRelTable('LIKES', {
  from: 'User',
  to: 'Post',
  properties: {
    likedAt: 'int64'
  }
});

// Create indexes
await api.schema.createIndex('User', 'email');
await api.schema.createIndex('Post', ['title', 'createdAt']);

// List all tables
const tables = await api.schema.getTables();
console.log('Tables:', tables);

// Cleanup
await api.close();
await db.close();
```

### Schema Migration Style

For idempotent schema creation (useful for migrations):

```javascript
const { Database, CongraphDBAPI } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const api = new CongraphDBAPI(db);

// Define your complete schema
const schema = {
  nodeTables: [
    {
      name: 'User',
      properties: { id: 'string', name: 'string', age: 'int64' },
      primaryKey: 'id'
    },
    {
      name: 'Post',
      properties: { id: 'string', title: 'string', content: 'string' },
      primaryKey: 'id'
    }
  ],
  relTables: [
    {
      name: 'AUTHORED',
      from: 'User',
      to: 'Post',
      properties: { createdAt: 'int64' }
    }
  ]
};

// Ensure schema exists (idempotent - safe to run multiple times)
await api.schema.ensureSchema(schema);
```

### Direct Connection Methods

You can also use schema methods directly on a connection:

```javascript
const { Database } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const conn = db.createConnection();

// Create node table
await conn.createNodeTable('User', [
  { name: 'id', type: 'STRING', nullable: false },
  { name: 'name', type: 'STRING', nullable: false },
  { name: 'age', type: 'INT64', nullable: true }
], 'id');

// Create relationship table
await conn.createRelTable('KNOWS', 'User', 'User', [
  { name: 'since', type: 'INT64', nullable: false }
]);

// Get all tables
const tables = await conn.getTables();
for (const table of tables) {
  console.log(`Table: ${table.name} (${table.table_type})`);
  for (const prop of table.properties) {
    console.log(`  - ${prop.name}: ${prop.type_}`);
  }
}

// Create index
await conn.createIndex('User', ['name']);

// Drop table
await conn.dropTable('OldTable');
```

### Supported Property Types

The Schema API supports the following property types:

| Type | Description | Example |
|------|-------------|---------|
| `bool` | Boolean | `{ active: 'bool' }` |
| `int8` | 8-bit signed integer | `{ flags: 'int8' }` |
| `int16` | 16-bit signed integer | `{ smallId: 'int16' }` |
| `int32` | 32-bit signed integer | `{ count: 'int32' }` |
| `int64` | 64-bit signed integer | `{ timestamp: 'int64' }` |
| `uint8` | 8-bit unsigned integer | `{ byte: 'uint8' }` |
| `uint16` | 16-bit unsigned integer | `{ short: 'uint16' }` |
| `uint32` | 32-bit unsigned integer | `{ id: 'uint32' }` |
| `uint64` | 64-bit unsigned integer | `{ bigId: 'uint64' }` |
| `float` | 32-bit floating point | `{ ratio: 'float' }` |
| `double` | 64-bit floating point | `{ score: 'double' }` |
| `string` | Variable-length string | `{ name: 'string' }` |
| `blob` | Binary data | `{ data: 'blob' }` |
| `date` | Date (no time) | `{ birthDate: 'date' }` |
| `timestamp` | Timestamp with timezone | `{ createdAt: 'timestamp' }` |
| `interval` | Time duration | `{ duration: 'interval' }` |
| `vector[]` | Fixed-size vector | `{ embedding: 'vector[128]' }` |

### PropertyTypes Constant (v0.1.8+)

For type-safe schema definitions, use the `PropertyTypes` constant:

```javascript
const { Database, PropertyTypes } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const conn = db.createConnection();

// Using PropertyTypes for type safety
await conn.createNodeTable('Document', [
  { name: 'id', type: PropertyTypes.String },
  { name: 'title', type: PropertyTypes.String },
  { name: 'tags', type: PropertyTypes.List },
  { name: 'embedding', type: PropertyTypes.Vector },
  { name: 'published', type: PropertyTypes.Bool },
  { name: 'views', type: PropertyTypes.Int64 },
  { name: 'score', type: PropertyTypes.Float64 },
], 'id');

// Available PropertyTypes
PropertyTypes.Bool       // Boolean values
PropertyTypes.Int8       // 8-bit signed integer
PropertyTypes.Int16      // 16-bit signed integer
PropertyTypes.Int32      // 32-bit signed integer
PropertyTypes.Int64      // 64-bit signed integer
PropertyTypes.UInt8      // 8-bit unsigned integer
PropertyTypes.UInt16     // 16-bit unsigned integer
PropertyTypes.UInt32     // 32-bit unsigned integer
PropertyTypes.UInt64     // 64-bit unsigned integer
PropertyTypes.Float      // 32-bit floating point
PropertyTypes.Double     // 64-bit floating point
PropertyTypes.String     // Variable-length string
PropertyTypes.Blob       // Binary data
PropertyTypes.Date       // Date (no time)
PropertyTypes.Timestamp  // Timestamp with timezone
PropertyTypes.Interval   // Time duration
PropertyTypes.List       // List/array type
PropertyTypes.Vector     // Fixed-size vector (for embeddings)
```

> **Use PropertyTypes for type-safe schema definitions and better IDE autocomplete.**

> **✅ Available in v0.1.7+**: The Schema API is fully implemented with TypeScript definitions. Use `PropertyTypes` constant for type-safe property type definitions.

## Next Steps

- [Queries](queries.md) — Learn how to query your schema
- [Transactions](transactions.md) — Work with transactions
