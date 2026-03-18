---
title: Vector Search Tutorial
date: 2024-03-14
description: Learn how to use HNSW indexes for semantic search with embeddings.
categories: [Tutorial, Deep Dive]
---

# Vector Search Tutorial

CongraphDB includes built-in support for vector similarity search using HNSW (Hierarchical Navigable Small World) indexes. This tutorial shows you how to build a semantic search application.

## What is Semantic Search?

Unlike keyword search, semantic search understands the *meaning* of text:

```javascript
// Keyword search: "dog" ≠ "puppy"
// Semantic search: "dog" ≈ "puppy" (similar meanings)
```

## Prerequisites

- Node.js 20+
- An embedding model (we'll use OpenAI in this example)

## Setup

```bash
npm install congraphdb openai
```

## Create a Document Store

```javascript
const { Database } = require('congraphdb');
const OpenAI = require('openai');

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function getEmbedding(text) {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
  });
  return response.data[0].embedding;
}

async function main() {
  const db = new Database('./doc-store.cgraph');
  db.init();
  const conn = db.createConnection();

  // Create schema with vector column
  await conn.query(`
    CREATE NODE TABLE Document(
      id STRING,
      title STRING,
      content STRING,
      embedding FLOAT_VECTOR[1536],
      PRIMARY KEY (id)
    )
  `);

  // Create HNSW index for fast search
  await conn.query(`
    CREATE HNSW INDEX ON Document(embedding, dim=1536, M=16)
  `);
```

## Add Documents

```javascript
  const documents = [
    {
      id: '1',
      title: 'Machine Learning Basics',
      content: 'Machine learning is a subset of artificial intelligence that enables systems to learn from data.',
    },
    {
      id: '2',
      title: 'Deep Learning Explained',
      content: 'Deep learning uses neural networks with multiple layers to learn patterns in data.',
    },
    {
      id: '3',
      title: 'Natural Language Processing',
      content: 'NLP enables computers to understand and generate human language using transformers.',
    },
    {
      id: '4',
      title: 'Computer Vision',
      content: 'Computer vision allows machines to interpret and understand visual information from images.',
    },
  ];

  for (const doc of documents) {
    const embedding = await getEmbedding(doc.content);
    await conn.query(`
      CREATE (d:Document {
        id: $id,
        title: $title,
        content: $content,
        embedding: $embedding
      })
    `, { ...doc, embedding });
  }
```

## Semantic Search

```javascript
  // Search by meaning, not keywords
  const query = 'how do computers learn';
  const queryEmbedding = await getEmbedding(query);

  const result = await conn.query(`
    MATCH (d:Document)
    RETURN d.title, d.content, d.embedding <-> $query AS distance
    ORDER BY distance
    LIMIT 3
  `, { query: queryEmbedding });

  console.log(`Search results for: "${query}"`);
  console.log();
  for (const row of result.getAll()) {
    console.log(`${row['d.title']}`);
    console.log(`  ${row['d.content']}`);
    console.log(`  Distance: ${row.distance.toFixed(4)}`);
    console.log();
  }

  /*
  Output:
  Search results for: "how do computers learn"

  Machine Learning Basics
    Machine learning is a subset of artificial intelligence...
    Distance: 0.1523

  Deep Learning Explained
    Deep learning uses neural networks with multiple layers...
    Distance: 0.1234

  Natural Language Processing
    NLP enables computers to understand...
    Distance: 0.2134
  */

  db.close();
}

main().catch(console.error);
```

## HNSW Parameters

Understanding HNSW parameters for your use case:

### M (max connections)

```javascript
// Default: 16
// Higher = more accurate, slower, more memory
CREATE HNSW INDEX ON Document(embedding, dim=1536, M=16)

// For small datasets (< 10K): M = 8-16
// For medium datasets (10K-100K): M = 16-32
// For large datasets (> 100K): M = 32-64
```

### ef_construction (build-time)

```javascript
// Default: 100
// Higher = better index quality, slower build
CREATE HNSW INDEX ON Document(embedding, dim=1536, M=16, ef_construction=100)
```

### ef_runtime (search-time)

Controlled at query time via the LIMIT clause:

```javascript
// More candidates = more accurate, slower
LIMIT 10  // ef_runtime ≈ 10 * 10 = 100
```

## Performance Tips

1. **Batch insertions**: Insert all documents before creating the index
2. **Dimension choice**: Lower dimensions (128-384) are faster
3. **Monitor build time**: Large indexes can take minutes to build

## Complete Example

```javascript
const { Database } = require('congraphdb');
const OpenAI = require('openai');

const openai = new OpenAI();

async function getEmbedding(text) {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
  });
  return response.data[0].embedding;
}

async function search(query) {
  const db = new Database('./doc-store.cgraph');
  db.init();
  const conn = db.createConnection();

  const queryEmbedding = await getEmbedding(query);

  const result = await conn.query(`
    MATCH (d:Document)
    RETURN d.title, d.content, d.embedding <-> $query AS distance
    ORDER BY distance
    LIMIT 3
  `, { query: queryEmbedding });

  db.close();
  return result.getAll();
}

// Usage
search('neural network training').then(console.log);
```

## Next Steps

- [Vector Search Guide](../../guide/vector-search.md) — More on vector search
- [HNSW Internals](../../internals/index-structures.md) — How HNSW works
- [Performance Guide](../../guide/performance.md) — Optimization tips

Happy searching! :mag:
