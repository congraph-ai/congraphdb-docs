# ConGraphDB TypeScript Migration Guide

This guide helps you migrate your ConGraphDB JavaScript projects to TypeScript.

## Table of Contents

- [Why Migrate?](#why-migrate)
- [Quick Start](#quick-start)
- [Migration Steps](#migration-steps)
- [Common Patterns](#common-patterns)
- [Removing Type Suppressions](#removing-type-suppressions)
- [Troubleshooting](#troubleshooting)

---

## Why Migrate?

### Benefits of TypeScript with ConGraphDB

1. **Compile-time error checking** - Catch bugs before runtime
2. **Better IntelliSense** - Auto-completion in your IDE
3. **Self-documenting code** - Types serve as documentation
4. **Safer refactoring** - Rename with confidence
5. **Schema validation** - Ensure data integrity at compile time

---

## Quick Start

### Step 1: Install TypeScript

```bash
npm install --save-dev typescript @types/node
```

### Step 2: Create tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

### Step 3: Rename Files

```bash
# Rename .js files to .ts
find src -name "*.js" -exec mv {} {}.ts \;

# Or use a tool like rename
# npm install -g rename
# rename .js .ts src/**/*.js
```

### Step 4: Start Migrating

```bash
# Check for type errors
npx tsc --noEmit
```

---

## Migration Steps

### Phase 1: Basic Types (Low Risk)

Start with adding basic types without changing logic:

```typescript
// Before: JavaScript
const db = new Database('./graph.cgraph')
const conn = db.createConnection()

// After: TypeScript
import { Database, Connection } from 'congraphdb'

const db: Database = new Database('./graph.cgraph')
const conn: Connection = db.createConnection()
```

### Phase 2: Type-Safe Nodes (Medium Risk)

Add type parameters to nodes and edges:

```typescript
// Before: JavaScript
const user = {
  _id: 'user-1',
  _label: 'User',
  name: 'Alice',
  age: 30
}

// After: TypeScript
import type { Node } from 'congraphdb/types'

interface UserProperties {
  name: string
  age: number
  email?: string
}

const user: Node<UserProperties> = {
  _id: 'user-1',
  _label: 'User',
  name: 'Alice',
  age: 30
}
```

### Phase 3: Result Types (Medium Risk)

Replace error throwing with result types:

```typescript
// Before: JavaScript
async function getUser(id: string) {
  const result = await conn.query(`MATCH (u:User {_id: $id}) RETURN u`, { id })
  if (!result.success) {
    throw new Error('User not found')
  }
  return result.data[0]
}

// After: TypeScript
import type { Result } from 'congraphdb/types'

async function getUser(id: string): Promise<Result<UserProperties>> {
  try {
    const result = await conn.query(`MATCH (u:User {_id: $id}) RETURN u`, { id })
    if (result.success) {
      return { success: true, data: result.data[0] }
    }
    return { success: false, error: new Error('User not found') }
  } catch (error) {
    return { success: false, error: error as Error }
  }
}
```

### Phase 4: Schema Definitions (High Risk)

Define schemas for your data:

```typescript
// Before: JavaScript
function validateUser(user) {
  return typeof user.name === 'string' && typeof user.age === 'number'
}

// After: TypeScript
import { defineNodeSchema, SchemaString, SchemaInt64 } from 'congraphdb/types'

const UserSchema = defineNodeSchema('User', {
  name: SchemaString(),
  age: SchemaInt64()
})

function validateUser(user: UserProperties) {
  const validation = UserSchema.validate(user)
  return validation.valid
}
```

---

## Common Patterns

### Pattern 1: Database Connection

```typescript
// Before
const db = new Database(path)
const conn = db.createConnection()

// After
import { Database, Connection } from 'congraphdb'

let db: Database
let conn: Connection

function connect(path: string): void {
  db = new Database(path)
  const result = db.createConnection()
  if (result.success) {
    conn = result.data
  } else {
    throw result.error
  }
}
```

### Pattern 2: Query Execution

```typescript
// Before
async function findUser(name) {
  const result = await conn.query(`MATCH (u:User {name: $name}) RETURN u`, { name })
  return result[0]
}

// After
import type { Result } from 'congraphdb/types'

async function findUser(name: string): Promise<Result<UserProperties>> {
  try {
    const result = await conn.query(`MATCH (u:User {name: $name}) RETURN u`, { name })
    if (result.success && result.data.length > 0) {
      return { success: true, data: result.data[0] }
    }
    return { success: false, error: new Error('User not found') }
  } catch (error) {
    return { success: false, error: error as Error }
  }
}
```

### Pattern 3: Node Creation

```typescript
// Before
function createUser(name, age, email) {
  return {
    _id: crypto.randomUUID(),
    _label: 'User',
    name,
    age,
    email
  }
}

// After
import type { TypedNode } from 'congraphdb/types'
import { UserSchema } from './schemas'

function createUser(properties: UserProperties): TypedNode<UserProperties> {
  return UserSchema.create(crypto.randomUUID(), properties)
}
```

### Pattern 4: Error Handling

```typescript
// Before
try {
  const result = await someOperation()
  console.log(result)
} catch (error) {
  console.error(error)
}

// After
import { isSuccess, isFailure } from 'congraphdb/types'

const result = await someOperation()
if (isSuccess(result)) {
  console.log(result.data)
} else if (isFailure(result)) {
  console.error(result.error.message)
}
```

---

## Removing Type Suppressions

### Remove @ts-nocheck

If you've been using `// @ts-nocheck` to suppress type errors:

```typescript
// Before
// @ts-nocheck
import { Database } from 'congraphdb/native'

const db = new Database('./graph.cgraph')

// After - Step 1: Remove @ts-nocheck and fix errors
import { Database } from 'congraphdb'

const db = new Database('./graph.cgraph')

// After - Step 2: Add types
import { Database } from 'congraphdb'

const db: Database = new Database('./graph.cgraph')
```

### Replace any Types

```typescript
// Before
function processNode(node: any) {
  console.log(node.name)
}

// After
interface NodeProperties {
  name: string
  [key: string]: unknown
}

function processNode(node: Node<NodeProperties>) {
  console.log(node.name)
}
```

### Fix Dynamic Property Access

```typescript
// Before
function getProperty(node, propertyName) {
  return node[propertyName]
}

// After - Option 1: Keyof type
function getProperty<T extends Record<string, unknown>>(
  node: T,
  propertyName: keyof T
): T[keyof T] {
  return node[propertyName]
}

// After - Option 2: String index with type guard
function getProperty(node: Record<string, unknown>, propertyName: string): unknown {
  return node[propertyName]
}
```

---

## Troubleshooting

### Issue: Cannot Find Module

**Problem:**
```
Cannot find module 'congraphdb' or its corresponding type declarations.
```

**Solution:**
```bash
# Install types
npm install congraphdb

# Or use type-only import
import type { Node } from 'congraphdb/types'
```

### Issue: Property Does Not Exist

**Problem:**
```
Property 'name' does not exist on type 'Node'.
```

**Solution:**
```typescript
// Add type parameter
import type { Node } from 'congraphdb/types'

interface UserProperties {
  name: string
}

const user: Node<UserProperties> = { /* ... */ }
console.log(user.name) // OK
```

### Issue: Type 'any' Not Assigned

**Problem:**
```
Type 'any' is not assignable to type 'never'.
```

**Solution:**
```typescript
// Define proper types instead of using any
interface UserProperties {
  name: string
  age: number
}

const users: UserProperties[] = []
```

### Issue: Strict Null Check Errors

**Problem:**
```
Object is possibly 'null' or 'undefined'.
```

**Solution:**
```typescript
// Option 1: Use type guard
if (user !== null && user !== undefined) {
  console.log(user.name)
}

// Option 2: Use non-null assertion (careful!)
console.log(user!.name)

// Option 3: Use optional chaining
console.log(user?.name)

// Option 4: Use strict mode types
import { isDefined } from 'congraphdb/strict'

if (isDefined(user)) {
  console.log(user.name)
}
```

---

## Migration Checklist

- [ ] Install TypeScript and @types/node
- [ ] Create tsconfig.json
- [ ] Rename .js files to .ts
- [ ] Add basic types (Database, Connection)
- [ ] Define interfaces for your data (UserProperties, etc.)
- [ ] Add type parameters to Node and Edge
- [ ] Replace error throwing with Result types
- [ ] Define schemas for your data models
- [ ] Remove all @ts-nocheck comments
- [ ] Replace all `any` types with proper types
- [ ] Run `npx tsc --noEmit` to verify no errors
- [ ] Run `npm run test:types` to verify type tests
- [ ] Update CI/CD to run type checking

---

## Resources

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [ConGraphDB TypeScript Guide](typescript.md)
- [JavaScript API Reference](../api/javascript.md)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
