# Vector Search

CongraphDB includes built-in support for vector similarity search using the HNSW (Hierarchical Navigable Small World) algorithm. This makes it ideal for AI/ML applications that work with embeddings.

## What are Embeddings?

Embeddings are numerical representations of data (text, images, audio) that capture semantic meaning. Similar items have similar embeddings.

## Creating a Vector Column

Define a table with a `FLOAT_VECTOR` column:

```javascript
await conn.query(`
  CREATE NODE TABLE Document(
    id STRING,
    content STRING,
    embedding FLOAT_VECTOR[128],
    PRIMARY KEY (id)
  )
`);
```

## Inserting Vectors

```javascript
// Assuming you have a function to generate embeddings
async function getEmbedding(text) {
  // Call your embedding model (OpenAI, local model, etc.)
  // Returns an array of 128 floats
  return [/* ...128 floats... */];
}

const embedding = await getEmbedding("Hello, world!");

await conn.query(`
  CREATE (d:Document {
    id: 'doc1',
    content: 'Hello, world!',
    embedding: $vec
  })
`, { vec: embedding });
```

## Vector Similarity Search

Use the `<->` operator for cosine similarity (recommended):

```javascript
const queryEmbedding = await getEmbedding("greetings");

const result = await conn.query(`
  MATCH (d:Document)
  RETURN d.id, d.content, d.embedding <-> $query AS distance
  ORDER BY distance
  LIMIT 5
`, { query: queryEmbedding });

for (const row of result.getAll()) {
  console.log(`${row.content} (distance: ${row.distance})`);
}
```

## Distance Operators

| Operator | Description | Use Case |
|----------|-------------|----------|
| `<->` | Cosine distance | **Recommended for embeddings** |
| `<=>` | Euclidean distance (L2) | General purpose |
| `<=` | Negative inner product | Some embedding models |

## Indexing Vectors

For large datasets, create an HNSW index for faster search:

```javascript
await conn.query(`
  CREATE HNSW INDEX ON Document(embedding, dim=128, M=16)
`);
```

### HNSW Parameters

| Parameter | Description | Default | Recommendation |
|-----------|-------------|---------|----------------|
| `dim` | Vector dimension | - | Must match your column |
| `M` | Max connections per node | 16 | Higher = more accurate, slower |
| `ef_construction` | Build-time candidates | 100 | Higher = better quality, slower build |

## Complete Example

```javascript
const { Database } = require('@congraph-ai/congraphdb');

async function semanticSearchExample() {
  const db = new Database('./semantic-search.cgraph');
  db.init();
  const conn = db.createConnection();

  // Create schema with vector column
  await conn.query(`
    CREATE NODE TABLE Document(
      id STRING,
      title STRING,
      content STRING,
      embedding FLOAT_VECTOR[384],
      PRIMARY KEY (id)
    )
  `);

  // Create HNSW index for fast search
  await conn.query(`
    CREATE HNSW INDEX ON Document(embedding, dim=384, M=16)
  `);

  // Insert documents with embeddings
  const docs = [
    { id: '1', title: 'Machine Learning', content: 'Introduction to ML algorithms' },
    { id: '2', title: 'Deep Learning', content: 'Neural networks and backpropagation' },
    { id: '3', title: 'Natural Language', content: 'Text processing and transformers' },
  ];

  for (const doc of docs) {
    const embedding = await getEmbedding(doc.content); // Your embedding function
    await conn.query(`
      CREATE (d:Document {
        id: $id,
        title: $title,
        content: $content,
        embedding: $embedding
      })
    `, { id: doc.id, title: doc.title, content: doc.content, embedding });
  }

  // Semantic search
  const query = "how do neural networks learn";
  const queryEmbedding = await getEmbedding(query);

  const result = await conn.query(`
    MATCH (d:Document)
    RETURN d.title, d.content, d.embedding <-> $query AS distance
    ORDER BY distance
    LIMIT 3
  `, { query: queryEmbedding });

  console.log('Search results for:', query);
  for (const row of result.getAll()) {
    console.log(`- ${row.title}: ${row.content}`);
  }

  db.close();
}
```

## Use Cases

- **Semantic Search** — Find documents by meaning, not keywords
- **Recommendation Systems** — Similar items, collaborative filtering
- **Image Search** — Find visually similar images
- **Anomaly Detection** — Find outliers based on distance
- **Deduplication** — Find near-duplicate records

## Tips

1. **Normalize embeddings** — Use L2 normalization for best results with cosine distance
2. **Batch insertions** — Insert all documents before creating the index for faster builds
3. **Dimension choice** — Lower dimensions (128-384) are faster; higher (768-1536) are more accurate
4. **Index tuning** — Start with default HNSW parameters, tune based on your data

## Next Steps

- [Performance](performance.md) — Optimization tips
- [Internals](../internals/index-structures.md) — How HNSW works
