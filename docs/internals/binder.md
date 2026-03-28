# Binder

The binder performs semantic analysis on parsed Cypher queries, converting the AST into a bound query ready for physical planning.

## Overview

```
AST (from Parser)
        │
        ▼
┌──────────────────┐
│  Semantic Analysis │
│  - Validation     │
│  - Type Checking  │
│  - Resolution     │
└──────────────────┘
        │
        ▼
   Bound Query
```

## Binder Structure

The binder is organized into modular components in `src/query/binder/`:

### Module Organization

```
src/query/binder/
├── mod.rs           # Module exports
├── binder.rs        # Main Binder struct
├── clause.rs        # Clause binding (MATCH, RETURN, etc.)
├── statement.rs     # Statement binding (queries vs schema)
├── expression.rs    # Expression binding and evaluation
├── pattern.rs       # Pattern binding (nodes, relationships)
└── types.rs         # Bound query type definitions
```

### Modular Design Benefits

The recent refactoring split the binder into focused modules:

- **Maintainability**: Each module has a single, clear responsibility
- **Extensibility**: Adding new Cypher features is easier
- **Testability**: Modules can be tested independently
- **Readability**: Code is more discoverable

## Binding Process

### 1. Clause Binding

Located in `clause.rs`, handles binding of individual Cypher clauses:

```cypher
MATCH (u:User)
WHERE u.age > 25
RETURN u.name
```

Binding steps:
1. **MATCH clause**: Bind nodes and relationships to tables
2. **WHERE clause**: Bind and validate filter expressions
3. **RETURN clause**: Bind projection items

### 2. Pattern Binding

Located in `pattern.rs`, handles graph pattern binding:

```cypher
MATCH (a:User)-[:KNOWS]->(b:User)
```

Binding steps:
1. **Node binding**: Resolve labels to node tables
2. **Relationship binding**: Resolve types to relationship tables
3. **Direction validation**: Ensure relationship direction matches schema
4. **Variable binding**: Track variable scopes

### 3. Expression Binding

Located in `expression.rs`, handles expression binding and type checking:

```cypher
WHERE u.age > 25 AND u.name STARTS WITH 'A'
```

Binding steps:
1. **Property access**: Validate property exists on node type
2. **Operators**: Type-check operands
3. **Functions**: Validate function names and argument types
4. **Literals**: Convert to internal Value types

## Binder Context

The binder maintains context during binding:

### BinderState

```rust
pub struct BinderState {
    // Variable bindings
    variables: HashMap<String, VariableBinding>,

    // Current scope for variable resolution
    scope: Vec<ScopeLevel>,

    // Catalog for table/property lookups
    catalog: Arc<Catalog>,

    // Bound clauses being built
    bound_clauses: Vec<BoundClause>,
}
```

### Variable Binding

Variables are bound to their sources:

```cypher
MATCH (u:User)-[:KNOWS]->(f:User)
RETURN u.name, f.name
```

Produces bindings:
```
u -> NodeBinding { table: "User", variable: "u" }
f -> NodeBinding { table: "User", variable: "f" }
```

## Type Checking

The binder performs type checking on expressions:

### Property Access

```cypher
MATCH (u:User)
WHERE u.age > 25
```

Type checking:
1. Verify `User` table has property `age`
2. Verify `age` is numeric type
3. Verify literal `25` is compatible

### Function Calls

```cypher
RETURN size(u.name)
```

Type checking:
1. Verify `size()` function exists
2. Verify `u.name` is string or list
3. Verify return type is numeric

## Error Handling

The binder produces detailed errors for invalid queries:

### Undefined Label

```cypher
MATCH (u:UndefinedLabel)
```

Error:
```
SemanticError: Label 'UndefinedLabel' does not exist
  --> MATCH (u:UndefinedLabel)
              ^^^^^^^^^^^^^
```

### Type Mismatch

```cypher
MATCH (u:User)
WHERE u.name > 100
```

Error:
```
SemanticError: Cannot compare STRING with INTEGER
  --> WHERE u.name > 100
                  ^^^^^^^^
```

### Undefined Variable

```cypher
MATCH (u:User)
RETURN x.name
```

Error:
```
SemanticError: Variable 'x' is not defined
  --> RETURN x.name
              ^
```

## Scope Management

The binder manages variable scopes:

### Single Clause Scope

```cypher
MATCH (u:User)
WHERE u.age > 25
RETURN u.name
```

Variables `u` is visible in WHERE and RETURN.

### Multiple Match Patterns

```cypher
MATCH (u:User)-[:KNOWS]->(f:User),
      (f)-[:WORKS_AT]->(c:Company)
RETURN u.name, c.name
```

Variable `f` from first pattern is available in second pattern.

### WITH Clause Scope

```cypher
MATCH (u:User)
WITH u.name AS name
WHERE name STARTS WITH 'A'
RETURN name
```

Variables after WITH are only those projected.

## Special Cases

### Relationship Binding

Relationships require special handling:

```cypher
MATCH (u:User)-[r:KNOWS]->(f:User)
RETURN r.since
```

Binding steps:
1. Bind `r` to relationship variable
2. Bind relationship type `KNOWS` to relationship table
3. Bind property access `r.since`
4. Verify `KNOWS` table has property `since`

### Optional Match

OPTIONAL MATCH creates nullable bindings:

```cypher
MATCH (u:User)
OPTIONAL MATCH (u)-[:WORKS_AT]->(c:Company)
RETURN u.name, c.name
```

Binding:
- `u` is always bound (non-nullable)
- `c` may be null if no relationship exists

### Pattern Comprehensions

Pattern comprehensions create list expressions:

```cypher
MATCH (u:User)
RETURN [(u)-[:KNOWS]->(f) | f.name] AS friends
```

Binding:
1. Create new scope for comprehension
2. Bind `f` within comprehension
3. Type-check comprehension expression
4. Verify return type is list

## See Also

- [Query Execution](query-execution.md) — Full query pipeline
- [Architecture](architecture.md) — System overview
- [Operators](operators.md) — Physical operators
- [Functions Reference](../guide/functions.md) — Built-in functions
