# Graph Algorithms

CongraphDB provides a comprehensive library of graph algorithms accessible via Cypher CALL syntax or JavaScript API.

## Available Algorithms

### Centrality Algorithms

Centrality algorithms identify the most important nodes in a graph.

#### PageRank

Measures node importance based on the importance of its neighbors.

```cypher
CALL algo.pagerank({dampingFactor: 0.85, maxIterations: 20}) YIELD nodeId, score
RETURN nodeId, score
ORDER BY score DESC
LIMIT 10
```

**Parameters:**
- `dampingFactor` (number, default: 0.85) - Probability of continuing random walk
- `maxIterations` (number, default: 20) - Maximum iterations
- `tolerance` (number, default: 1e-6) - Convergence tolerance

**Use Cases:**
- Identifying influential users in social networks
- Ranking web pages
- Finding key entities in knowledge graphs

#### Degree Centrality

Counts the number of relationships connected to each node.

```cypher
CALL algo.degree({direction: "Both", normalized: false}) YIELD nodeId, score
RETURN nodeId, score
ORDER BY score DESC
```

**Parameters:**
- `direction` (string, default: "Out") - "Out", "In", or "Both"
- `normalized` (boolean, default: false) - Normalize by graph size

**Use Cases:**
- Finding highly connected nodes
- Identifying potential hubs
- Quick influence assessment

#### Betweenness Centrality

Measures how often a node appears on shortest paths between other nodes.

```cypher
CALL algo.betweenness({direction: "Out"}) YIELD nodeId, score
RETURN nodeId, score
ORDER BY score DESC
```

**Parameters:**
- `direction` (string, default: "Out") - "Out", "In", or "Both"

**Use Cases:**
- Finding communication bottlenecks
- Identifying bridge nodes
- Network vulnerability analysis

#### Closeness Centrality

Measures how close a node is to all other nodes.

```cypher
CALL algo.closeness({direction: "Out"}) YIELD nodeId, score
RETURN nodeId, score
ORDER BY score DESC
```

**Parameters:**
- `direction` (string, default: "Out") - "Out", "In", or "Both"

**Use Cases:**
- Finding nodes that can quickly reach others
- Information propagation analysis
- Identifying central nodes

### Community Detection Algorithms

Discover clusters of densely connected nodes.

#### Louvain

Modularity-based community detection using hierarchical optimization.

```cypher
CALL algo.louvain({resolution: 1.0, maxIterations: 20}) YIELD nodeId, communityId
RETURN communityId, collect(nodeId) AS members
ORDER BY size(members) DESC
```

**Parameters:**
- `resolution` (number, default: 1.0) - Higher values create smaller communities
- `maxIterations` (number, default: 20) - Maximum iterations per level

**Use Cases:**
- Social network communities
- Document clustering
- Market segmentation

#### Leiden

Improved version of Louvain with better community guarantees.

```cypher
CALL algo.leiden({resolution: 1.0, maxIterations: 20}) YIELD nodeId, communityId
RETURN communityId, count(*) AS size
ORDER BY size DESC
```

**Parameters:**
- `resolution` (number, default: 1.0) - Community resolution
- `maxIterations` (number, default: 20) - Maximum iterations

**Use Cases:**
- High-quality community detection
- When Louvain produces poorly connected communities
- Large-scale network analysis

#### Spectral Clustering

Parallel spectral clustering using Rayon for multi-core performance.

```cypher
CALL algo.spectral({maxIterations: 20, numClusters: 5}) YIELD nodeId, clusterId
RETURN clusterId, count(*) AS size
```

**Parameters:**
- `maxIterations` (number, default: 20) - Maximum iterations
- `numClusters` (number) - Number of clusters (optional)

**Use Cases:**
- Image segmentation
- Large graphs with multi-core systems
- When cluster count is known

#### SLPA

Speaker-Listener Label Propagation Algorithm for overlapping communities.

```cypher
CALL algo.slpa({threshold: 0.1, maxIterations: 20}) YIELD nodeId, communities
WHERE size(communities) > 1
RETURN nodeId, communities
ORDER BY size(communities) DESC
```

**Parameters:**
- `threshold` (number, default: 0.1) - Minimum membership probability
- `maxIterations` (number, default: 20) - Maximum iterations

**Use Cases:**
- Social networks with overlapping groups
- Finding nodes with multiple affiliations
- Tag recommendation

#### Infomap

Information-theoretic community detection using map equation.

```cypher
CALL algo.infomap({maxIterations: 20}) YIELD nodeId, communityId
RETURN communityId, collect(nodeId) AS members
ORDER BY size(members) DESC
```

**Parameters:**
- `maxIterations` (number, default: 20) - Maximum iterations

**Use Cases:**
- Flow-based networks
- Citation networks
- When community hierarchy matters

#### Label Propagation

Fast community detection using label spreading.

```cypher
CALL algo.labelPropagation({maxIterations: 20}) YIELD nodeId, label
RETURN label, count(*) AS size
ORDER BY size DESC
```

**Parameters:**
- `maxIterations` (number, default: 20) - Maximum iterations

**Use Cases:**
- Very large graphs (fastest algorithm)
- Approximate community detection
- Initial clustering for refinement

#### Walktrap

Random walk-based community detection.

```cypher
CALL algo.walktrap({maxIterations: 20}) YIELD nodeId, clusterId
RETURN clusterId, count(*) AS size
ORDER BY size DESC
```

**Parameters:**
- `maxIterations` (number, default: 20) - Maximum iterations

**Use Cases:**
- Social networks
- When random walk behavior is meaningful
- Medium-sized graphs

#### Connected Components

Find weakly connected components.

```cypher
CALL algo.connectedComponents({direction: "Out"}) YIELD nodeId, componentId
RETURN componentId, count(*) AS size
ORDER BY size DESC
```

**Parameters:**
- `direction` (string, default: "Out") - "Out" or "Both"

**Use Cases:**
- Finding disconnected subgraphs
- Graph connectivity analysis
- Data quality checks

#### Strongly Connected Components (SCC)

Find strongly connected components in directed graphs.

```cypher
CALL algo.scc() YIELD nodeId, componentId
RETURN componentId, count(*) AS size
ORDER BY size DESC
```

**Use Cases:**
- Finding cycles in directed graphs
- Analyzing strongly connected regions
- Dependency analysis

### Path Algorithms

#### Dijkstra

Find shortest paths with weighted edges.

```cypher
CALL algo.dijkstra({weightProperty: "cost", direction: "Out"}) YIELD target, cost, path
RETURN target, cost, path
ORDER BY cost
```

**Parameters:**
- `weightProperty` (string) - Property name for edge weights
- `direction` (string, default: "Out") - "Out", "In", or "Both"

**Use Cases:**
- Route planning
- Network optimization
- Cost analysis

### Traversal Algorithms

#### BFS (Breadth-First Search)

Level-by-level graph traversal.

```cypher
CALL algo.bfs({maxDepth: 3, direction: "Out"}) YIELD nodeId, depth
RETURN depth, count(*) AS count
ORDER BY depth
```

**Parameters:**
- `maxDepth` (number) - Maximum traversal depth
- `direction` (string, default: "Out") - "Out", "In", or "Both"

**Use Cases:**
- Finding nearby nodes
- Level-based analysis
- Social network reach

#### DFS (Depth-First Search)

Deep graph traversal.

```cypher
CALL algo.dfs({maxDepth: 3, direction: "Out"}) YIELD nodeId, depth
RETURN nodeId, depth
ORDER BY depth
```

**Parameters:**
- `maxDepth` (number) - Maximum traversal depth
- `direction` (string, default: "Out") - "Out", "In", or "Both"

**Use Cases:**
- Path exploration
- Cycle detection
- Deep graph analysis

### Analytics

#### Triangle Count

Count triangles (3-cliques) in the graph.

```cypher
CALL algo.triangleCount() YIELD totalTriangles, nodeTriangles
RETURN totalTriangles
```

**Returns:**
- `totalTriangles` - Total number of triangles in the graph
- `nodeTriangles` - Array of {nodeId, count} for each node

**Use Cases:**
- Measuring graph clustering
- Social network analysis (friend triangles)
- Network density assessment

## Algorithm Configuration

### Common Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `direction` | string | "Out" | "Out", "In", or "Both" |
| `maxIterations` | number | 20 | Maximum iterations for iterative algorithms |
| `tolerance` | number | 1e-6 | Convergence tolerance |
| `normalized` | boolean | false | Whether to normalize scores |

### Community Detection Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resolution` | number | 1.0 | Higher = smaller communities (Louvain/Leiden) |
| `threshold` | number | 0.1 | Community membership threshold (SLPA) |

### Centrality Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dampingFactor` | number | 0.85 | PageRank damping factor |

## JavaScript API

### Running Algorithms

```javascript
const { Database } = require('congraphdb');

const db = new Database('./my-graph.cgraph');
await db.init();
const conn = db.createConnection();

// Run PageRank algorithm
const resultJson = conn.runAlgorithmSync('pagerank', JSON.stringify({
  dampingFactor: 0.85,
  maxIterations: 20
}));

const scores = JSON.parse(resultJson);

console.log('PageRank Results:');
scores.forEach(({ nodeId, score }) => {
  console.log(`  Node ${nodeId}: ${score.toFixed(4)}`);
});
```

### Algorithm Helper Methods (SDK)

```javascript
// Using the SDK with convenience methods
import { CongraphSDK } from '@congraph-ai/sdk';

const sdk = new CongraphSDK('./my-graph.cgraph');
await sdk.init();

// PageRank with convenience method
const pageRankResults = await sdk.pageRank({
  dampingFactor: 0.85,
  maxIterations: 20
});

// Community detection
const communities = await sdk.detectCommunities('louvain', {
  resolution: 1.0
});

// Shortest path
const paths = await sdk.shortestPath('distance');
```

## Complete Examples

### Social Influence Analysis

```javascript
// Find top influencers using PageRank
const result = conn.runAlgorithmSync('pagerank', '{"dampingFactor": 0.85}');
const scores = JSON.parse(result);

// Get top 10
const topInfluencers = scores
  .sort((a, b) => b.score - a.score)
  .slice(0, 10);

console.log('Top Influencers:');
for (const { nodeId, score } of topInfluencers) {
  const user = await conn.query(`
    MATCH (u:User {id: '${nodeId}'})
    RETURN u.name
  `);
  console.log(`  ${user[0]['u.name']}: ${score.toFixed(4)}`);
}
```

### Community Detection

```javascript
// Detect communities using Louvain
const result = conn.runAlgorithmSync('louvain', '{"resolution": 1.0}');
const communities = JSON.parse(result);

// Group by community
const communityMap = {};
for (const { nodeId, communityId } of communities) {
  if (!communityMap[communityId]) {
    communityMap[communityId] = [];
  }
  communityMap[communityId].push(nodeId);
}

// Print communities
console.log('Detected Communities:');
for (const [id, members] of Object.entries(communityMap)) {
  console.log(`  Community ${id}: ${members.length} members`);
}
```

### Overlapping Communities

```javascript
// Find users with multiple community memberships
const result = conn.runAlgorithmSync('slpa', '{"threshold": 0.15}');
const overlapping = JSON.parse(result);

console.log('Users with Multiple Affiliations:');
for (const { nodeId, communities } of overlapping) {
  if (communities.length > 1) {
    console.log(`  Node ${nodeId}: ${communities.join(', ')}`);
  }
}
```

## Performance Considerations

### Algorithm Complexity

| Algorithm | Time Complexity | Space Complexity | Best Graph Size |
|-----------|----------------|------------------|-----------------|
| PageRank | O(k × \|E\|) | O(\|V\|) | Any |
| Betweenness | O(\|V\| × \|E\|) | O(\|V\| + \|E\|) | < 10K nodes |
| Louvain | O(\|E\| log \|V\|) | O(\|V\| + \|E\|) | Any |
| Leiden | O(\|E\| log \|V\|) | O(\|V\| + \|E\|) | Any |
| Spectral | O(\|V\|³) | O(\|V\|²) | < 5K nodes |
| SLPA | O(k × \|E\|) | O(\|V\| × k) | Any |
| Dijkstra | O(\|E\| + \|V\| log \|V\|) | O(\|V\|) | Any |
| BFS/DFS | O(\|V\| + \|E\|) | O(\|V\|) | Any |
| Triangle Count | O(\|E\| × √\|E\|) | O(\|V\|) | Any |

### Optimization Tips

1. **Use appropriate algorithms** - PageRank is faster than Betweenness for large graphs
2. **Leverage direction** - Use "Out" direction when possible for better cache locality
3. **Tune iterations** - Start with default maxIterations, increase only if needed
4. **Consider resolution** - Higher resolution = more communities (slower)

## Next Steps

- [Algorithm Internals](../internals/algorithms.md) — Implementation details
- [Cypher Reference](../guide/queries.md) — Query language syntax
