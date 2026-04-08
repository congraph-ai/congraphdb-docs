# ConGraphDB TypeScript Guide

This guide covers using ConGraphDB with TypeScript for type-safe graph database operations.

## Table of Contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Type-Safe Operations](#type-safe-operations)
- [Schema-First Development](#schema-first-development)
- [Query Builder](#query-builder)
- [ORM Pattern](#orm-pattern)
- [Strict Mode](#strict-mode)
- [Type-Only Imports](#type-only-imports)
- [Best Practices](#best-practices)

---

## Installation

```bash
npm install congraphdb
```

For TypeScript users, install the type definitions are included:

```bash
npm install --save-dev typescript @types/node
```

---

## Basic Usage

### Import Standard Types

```typescript
import { Database, Connection } from 'congraphdb'

const db = new Database('./my-graph.cgraph')
const conn = db.createConnection()
```

### Type-Safe Nodes and Edges

```typescript
import type { Node, Edge } from 'congraphdb/types'

interface UserProperties {
  name: string
  age: number
  email?: string
}

interface KnowsProperties {
  since: number
  strength?: number
}

// Type-safe node
const user: Node<UserProperties> = {
  _id: 'user-1',
  _label: 'User',
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
}

// Type-safe edge
const knows: Edge<KnowsProperties> = {
  _id: 'edge-1',
  _type: 'KNOWS',
  _from: 'user-1',
  _to: 'user-2',
  since: 2020
}
```

---

## Type-Safe Operations

### Result Types

```typescript
import type { Result, isSuccess, unwrap } from 'congraphdb/types'

async function getUser(id: string): Promise<Result<UserProperties>> {
  try {
    const result = await conn.query(`MATCH (u:User {_id: $id}) RETURN u`, { id })
    if (result.success) {
      return { success: true, data: result.data[0] }
    }
    return { success: false, error: new Error('Query failed') }
  } catch (error) {
    return { success: false, error: error as Error }
  }
}

// Usage
const result = await getUser('user-1')
if (isSuccess(result)) {
  console.log(result.data.name) // Type-safe access
}
```

### Type Guards

```typescript
import { isSuccess, isFailure, unwrapOr } from 'congraphdb/types'

const result = await someOperation()

if (isSuccess(result)) {
  console.log(result.data) // TypeScript knows this is T
} else if (isFailure(result)) {
  console.error(result.error) // TypeScript knows this is Error
}

// Get value or default
const value = unwrapOr(result, defaultValue)
```

---

## Schema-First Development

### Define Node Schema

```typescript
import { defineNodeSchema, SchemaString, SchemaInt64, SchemaBoolean } from 'congraphdb/types'

const UserSchema = defineNodeSchema('User', {
  name: SchemaString(),
  age: SchemaInt64(),
  email: SchemaString().optional(),
  active: SchemaBoolean().withDefault(true)
})

// Validate properties
const validation = UserSchema.validate({ name: 'Alice', age: 30 })
if (!validation.valid) {
  console.error(validation.errors)
}
```

### Define Relationship Schema

```typescript
import { defineRelationshipSchema, SchemaInt64, SchemaFloat } from 'congraphdb/types'

const KnowsSchema = defineRelationshipSchema('KNOWS', 'User', 'User', {
  since: SchemaInt64(),
  strength: SchemaFloat().optional()
})
```

### Define Complete Graph Schema

```typescript
import { defineGraph } from 'congraphdb/types'

const graphSchema = defineGraph({
  nodes: {
    User: {
      properties: {
        name: { type: 'string', required: true },
        age: { type: 'int64', required: true },
        email: { type: 'string', required: false }
      },
      primaryKey: 'name'
    },
    Document: {
      properties: {
        title: { type: 'string', required: true },
        content: { type: 'string', required: true }
      },
      primaryKey: 'title'
    }
  },
  relationships: {
    KNOWS: {
      from: 'User',
      to: 'User',
      properties: {
        since: { type: 'int64', required: true }
      }
    },
    WROTE: {
      from: 'User',
      to: 'Document',
      properties: {}
    }
  }
})

// Validate entire schema
const schemaValidation = graphSchema.validate()
```

---

## Query Builder

### Basic Queries

```typescript
import { QueryBuilder, match, findByProperty } from 'congraphdb/types'

// Find users over 18
const query = new QueryBuilder<{ name: string; age: number }>()
  .match('u', 'User')
  .where('u.age', '>', 18)
  .return('u.name', 'u.age')

const result = await conn.query(query.build())
```

### Helper Functions

```typescript
// Find by label
const users = await findByProperty('User', 'age', '>', 18)

// Find by property
const alice = await findByProperty('User', 'name', '=', 'Alice')

// Find related nodes
const friends = await findRelated('user-1', 'KNOWS', 'User', 'out')
```

### Type-Safe Query Results

```typescript
import type { TypedQueryResult } from 'congraphdb/types'

const query = match<{ name: string }>('u', 'User')
  .return('u.name')

const result: TypedQueryResult<{ name: string }> = await conn.query(query.build())

for (const row of result) {
  console.log(row.name) // Type-safe
}
```

---

## ORM Pattern

### Define Model

```typescript
import { Model, Relation } from 'congraphdb/types'

class User extends Model<UserProperties> {
  static tableName = 'users'
  static schema = UserSchema

  // Define relationships
  friends = Relation('hasMany', User, { relType: 'KNOWS', direction: 'both' })
  documents = Relation('hasMany', Document, { relType: 'WROTE', direction: 'out' })
}

// Create user
const user = User.create({
  name: 'Alice',
  age: 30,
  email: 'alice@example.com'
})

await user.save(conn)
```

### Active Record Pattern

```typescript
import { ActiveRecord } from 'congraphdb/types'

class User extends ActiveRecord<UserProperties> {
  static tableName = 'users'
}

// Set connection
ActiveRecord.setConnection(conn)

// Find by ID
const user = await User.findById('user-1')

// Find where
const adults = await User.findWhere({ age: { $gt: 18 } })

// Create new
const newUser = await User.create({
  name: 'Bob',
  age: 25
})
```

### Repository Pattern

```typescript
import { Repository } from 'congraphdb/types'

const userRepo = new Repository<UserProperties>(conn, 'users', UserSchema)

// CRUD operations
const user = await userRepo.findById('user-1')
const allUsers = await userRepo.findAll()
const adults = await userRepo.findBy('age', '>', 18)
const newUser = await userRepo.create({ name: 'Charlie', age: 35 })
const updated = await userRepo.update('user-1', { age: 31 })
const deleted = await userRepo.delete('user-1')
const count = await userRepo.count()
```

---

## Strict Mode

Enable strict null checking for better type safety:

```typescript
// Import from strict mode
import { StrictNode, createStrictNode, isDefined, assertNotNull } from 'congraphdb/strict'

interface UserProperties {
  name: string
  age: number
  email?: string
}

// Strict node - null not allowed, use undefined instead
const user = createStrictNode('user-1', 'User', {
  name: 'Alice',
  age: 30
  // email is undefined (not null)
})

// Type guards
if (isDefined(user.email)) {
  console.log(user.email.toUpperCase()) // TypeScript knows it's defined
}

// Assert
assertNotNull(user.age, 'Age must be set')
```

---

## Type-Only Imports

For projects that don't need the native bindings at compile time:

```typescript
// Type-only import - no runtime dependency
import type { Node, Edge, Result, QueryBuilder } from 'congraphdb/types'

function processNode(node: Node<{ name: string }>) {
  console.log(node._id, node.name)
}

// This works even if the native module isn't installed
// Perfect for:
// - Library authors
// - Frontend projects
// - CI/CD environments
```

---

## Best Practices

### 1. Use Generic Type Parameters

```typescript
// Good - Type-safe
function processUser(user: Node<{ name: string; age: number }>) {
  console.log(user.name, user.age)
}

// Avoid - Loose typing
function processUser(user: Node) {
  console.log(user.name) // Type is 'any'
}
```

### 2. Use Schema Definitions

```typescript
// Good - Schema-driven
const UserSchema = defineNodeSchema('User', {
  name: SchemaString(),
  age: SchemaInt64()
})

// Avoid - Manual validation
function validateUser(user: any): boolean {
  return typeof user.name === 'string' && typeof user.age === 'number'
}
```

### 3. Use Result Types for Error Handling

```typescript
// Good - Explicit error handling
async function getUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.find(id)
    return { success: true, data: user }
  } catch (error) {
    return { success: false, error: error as Error }
  }
}

// Avoid - Throwing errors
async function getUser(id: string): Promise<User> {
  return await db.find(id) // May throw
}
```

### 4. Use Type Guards

```typescript
// Good - Type-safe narrowing
if (isSuccess(result)) {
  console.log(result.data.name)
}

// Avoid - Manual type checking
if (result.success) {
  console.log((result as any).data.name)
}
```

### 5. Use Strict Mode for New Projects

```typescript
// Good - Strict from start
import { StrictNode } from 'congraphdb/strict'

// Avoid - Loose types that need migration later
import { Node } from 'congraphdb'
```

---

## Type Definitions Reference

### Core Types

| Type | Description |
|------|-------------|
| `Node<T>` | Graph node with typed properties |
| `Edge<T>` | Graph edge with typed properties |
| `Path<N, E>` | Path through the graph |
| `Result<T, E>` | Discriminated union for results |
| `JsonValue` | Valid JSON value types |

### Schema Types

| Type | Description |
|------|-------------|
| `NodeSchema<T>` | Node schema definition |
| `RelationshipSchema<T>` | Relationship schema definition |
| `GraphSchema` | Complete graph schema |
| `PropertyDef` | Property definition |

### Query Types

| Type | Description |
|------|-------------|
| `QueryBuilder<T>` | Type-safe query builder |
| `TypedQueryResult<T>` | Typed query result |
| `QueryRow<T>` | Single query row |

### ORM Types

| Type | Description |
|------|-------------|
| `Model<T>` | Base model class |
| `Repository<T>` | Repository pattern |
| `ActiveRecord<T>` | Active Record pattern |
| `Relation<T>` | Relationship definition |

### Strict Types

| Type | Description |
|------|-------------|
| `StrictNode<T>` | Node with strict null checking |
| `StrictEdge<T>` | Edge with strict null checking |
| `StrictPropertyAccess` | Strict property access |

---

## Examples

See the [examples](../examples/) directory for complete TypeScript examples:

- [basic-usage.ts](../examples/basic-usage.ts) - Basic CRUD operations
- [schema-first.ts](../examples/schema-first.ts) - Schema-first development
- [query-builder.ts](../examples/query-builder.ts) - Query builder usage
- [orm-pattern.ts](../examples/orm-pattern.ts) - ORM pattern
- [strict-mode.ts](../examples/strict-mode.ts) - Strict mode usage

---

## Further Reading

- [JavaScript API Reference](../api/javascript.md)
- [TypeScript Migration Guide](typescript-migration.md)
- [Cypher Query Language](queries.md)
