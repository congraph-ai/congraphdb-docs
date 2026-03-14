# List Operators

Operators for working with arrays and lists.

## List Literals

Create lists using square brackets:

```cypher
-- List of integers
RETURN [1, 2, 3, 4, 5] AS numbers

-- List of strings
RETURN ['Alice', 'Bob', 'Charlie'] AS names

-- Mixed types
RETURN [1, 'two', 3.0, true] AS mixed

-- Empty list
RETURN [] AS empty
```

## List Indexing

Access elements by zero-based index:

```cypher
-- Get first element
RETURN names[0] AS first_name

-- Get third element
RETURN numbers[2] AS third_number

-- Negative index (from end)
RETURN names[-1] AS last_name
```

## List Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `IN` | Check if element is in list | `'Alice' IN names` |
| `+` | Concatenate lists | `[1, 2] + [3, 4]` |
| `[start..end]` | Slice list | `names[0..2]` |
| `size()` | Get list length | `size(list)` |

## Examples

### IN Operator

```cypher
-- Find users in specific cities
MATCH (u:User)
WHERE u.city IN ['New York', 'Los Angeles', 'Chicago']
RETURN u.name, u.city

-- Check if value exists
RETURN 'Alice' IN ['Bob', 'Charlie']  // false
```

### List Concatenation

```cypher
-- Combine two lists
RETURN [1, 2] + [3, 4] AS combined
-- Result: [1, 2, 3, 4]

-- Append to list
RETURN u.tags + ['new-tag'] AS updated_tags
```

### List Slicing

```cypher
-- First three elements
RETURN names[0..2] AS first_three

-- From index 2 to end
RETURN names[2..] AS from_second

-- From start to index 3
RETURN names[..3] AS first_three

-- Last two elements
RETURN names[-2..] AS last_two
```

### List Comprehension

Filter and transform lists:

```cypher
-- Filter: even numbers only
RETURN [x IN [1, 2, 3, 4, 5] WHERE x % 2 = 0 | x]
-- Result: [2, 4]

-- Transform: double each number
RETURN [x IN [1, 2, 3] | x * 2]
-- Result: [2, 4, 6]

-- Both filter and transform
RETURN [x IN [1, 2, 3, 4, 5] WHERE x > 2 | x ^ 2]
-- Result: [9, 16, 25]
```

### List Functions

```cypher
-- Get list length
RETURN size([1, 2, 3, 4, 5]) AS count
-- Result: 5

-- Get first element
RETURN head([1, 2, 3]) AS first
-- Result: 1

-- Get last element
RETURN last([1, 2, 3]) AS last
-- Result: 3

-- Get all but first
RETURN tail([1, 2, 3, 4]) AS rest
-- Result: [2, 3, 4]

-- Collect values into list
RETURN COLLECT(u.name) AS user_names
```

## Working with Lists in Queries

### Unnest Lists

```cypher
-- Match against list values
WITH [1, 2, 3] AS ids
UNWIND ids AS id
MATCH (u:User {id: id})
RETURN u
```

### Collect Results

```cypher
-- Collect all matching names
MATCH (u:User)
WHERE u.age > 25
RETURN COLLECT(u.name) AS names
-- Result: ['Alice', 'Bob', 'Charlie']
```

### List Parameters

```javascript
// Pass list from JavaScript
const cities = ['New York', 'LA', 'Chicago'];
await conn.query(`
  MATCH (u:User)
  WHERE u.city IN $cities
  RETURN u
`, { cities });
```

## NULL Handling

- Lists can contain NULL: `[1, NULL, 3]`
- `NULL IN list` returns NULL
- `size(NULL)` returns NULL

```cypher
-- NULL in list
RETURN NULL IN [1, 2, NULL]  // NULL

-- Index out of bounds returns NULL
RETURN [1, 2, 3][10]  // NULL
```

## Array Columns

CongraphDB supports array columns:

```javascript
-- Create table with array column
await conn.query(`
  CREATE NODE TABLE User(
    name STRING,
    tags INT64[],
    scores FLOAT64[],
    PRIMARY KEY (name)
  )
`);

-- Insert with arrays
await conn.query(`
  CREATE (u:User {
    name: 'Alice',
    tags: [1, 2, 3],
    scores: [95.5, 87.0, 92.3]
  })
`);

-- Query array elements
await conn.query(`
  MATCH (u:User {name: 'Alice'})
  RETURN u.tags[0], u.scores[1]
`);
```

## Performance Tips

| Operation | Performance |
|-----------|-------------|
| `IN` with small list | Fast |
| `IN` with large list | Slow (consider index) |
| List comprehension | O(n) |
| `size()` | O(1) |

## See Also

- [List Functions](../api/cypher.md#list) — Complete function reference
- [Data Types](../guide/schemas.md) — Supported column types
