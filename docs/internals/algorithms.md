# Algorithm Internals

This document describes the internal architecture and implementation of CongraphDB's graph algorithm module.

## Architecture

The algorithm module (`src/algorithm/`) provides graph algorithms that operate directly on the table layer for maximum performance.

```
src/algorithm/
├── mod.rs              # Main exports
├── config.rs           # AlgorithmConfig, AlgorithmResult
├── traversal/          # BFS, DFS
│   ├── bfs.rs
│   └── dfs.rs
├── path/               # Dijkstra, Bidirectional Dijkstra
│   └── dijkstra.rs
├── centrality/         # PageRank, Betweenness, Closeness, Degree
│   ├── pagerank.rs
│   ├── betweenness.rs
│   ├── closeness.rs
│   └── degree.rs
├── community/          # Community detection algorithms
│   ├── louvain.rs
│   ├── leiden.rs
│   ├── spectral.rs
│   ├── slpa.rs
│   ├── infomap.rs
│   ├── label_propagation.rs
│   ├── walktrap.rs
│   ├── hierarchical.rs
│   ├── scc.rs
│   └── components.rs
└── analytics/          # Triangle count
    └── triangles.rs
```

## Configuration

All algorithms share a common configuration structure:

```rust
pub struct AlgorithmConfig {
    pub direction: Direction,
    pub max_iterations: Option<usize>,
    pub tolerance: Option<f64>,
    pub damping_factor: Option<f64>,
    pub resolution: Option<f64>,
    pub threshold: Option<f64>,
    pub weight_property: Option<String>,
    pub max_depth: Option<usize>,
}

pub enum Direction {
    Out,
    In,
    Both,
}

pub enum AlgorithmResult {
    NodeScores(Vec<(NodeOffset, f64)>),      // Centrality scores
    NodeLabels(Vec<(NodeOffset, u64)>),      // Community assignments
    TraversalOrder(Vec<(NodeOffset, usize)>), // BFS/DFS order
    ShortestPaths(Vec<PathResult>),          // Dijkstra results
    TriangleCount(TriangleCountResult),      // Triangle counts
    Streaming { ... },                        // Batched results
}
```

## Centrality Algorithms

### PageRank

**File:** `src/algorithm/centrality/pagerank.rs`

PageRank uses an iterative algorithm to compute node importance based on the importance of incoming neighbors.

**Algorithm:**
1. Initialize all nodes with equal score (1.0)
2. For each iteration:
   - Each node distributes its score to outgoing neighbors
   - Apply damping factor (typically 0.85)
   - Add random jump probability
3. Check convergence (max change < tolerance)
4. Return final scores

**Key Implementation Details:**
- Uses CSR (Compressed Sparse Row) structures for efficient adjacency access
- Atomic operations for thread-safe score updates
- Early termination when converged

### Betweenness Centrality

**File:** `src/algorithm/centrality/betweenness.rs`

Computes how often a node appears on shortest paths between all node pairs using Brandes' algorithm.

**Algorithm:**
1. For each source node:
   - Run single-source shortest paths
   - Accumulate dependency scores
2. Sum partial betweenness scores
3. Normalize by graph size

**Complexity:** O(V × E) for unweighted, O(V × E + V² log V) for weighted

### Closeness Centrality

**File:** `src/algorithm/centrality/closeness.rs`

Measures the average distance from a node to all other nodes.

**Algorithm:**
1. For each node:
   - Run BFS to find distances to all other nodes
   - Compute reciprocal of average distance
2. Return scores

**Complexity:** O(V × (V + E))

### Degree Centrality

**File:** `src/algorithm/centrality/degree.rs`

Counts the number of edges connected to each node.

**Algorithm:**
- Direct count from adjacency lists
- Optionally normalize by (V - 1)

**Complexity:** O(V + E)

## Community Detection Algorithms

### Louvain

**File:** `src/algorithm/community/louvain.rs`

Hierarchical modularity optimization using greedy label assignment.

**Algorithm:**
1. **Modularity Optimization:**
   - For each node, try moving to neighbor's community
   - Keep move if it increases modularity
   - Repeat until no improvements

2. **Community Aggregation:**
   - Collapse communities into super-nodes
   - Create weighted edges between super-nodes

3. **Repeat** on aggregated graph

**Key Features:**
- Resolution parameter controls community size
- Multiple passes for refinement
- Returns hierarchical community structure

### Leiden

**File:** `src/algorithm/community/leiden.rs`

Improved version of Louvain with guaranteed well-connected communities.

**Algorithm:**
1. Similar to Louvain with refinement phase
2. **Refinement:** After each move, ensure community remains connected
3. **Guarantee:** No poorly connected communities

**Advantages over Louvain:**
- Better community quality
- Faster convergence
- Guaranteed connectivity

### Spectral Clustering

**File:** `src/algorithm/community/spectral.rs`

Parallel spectral clustering using Rayon for multi-core performance.

**Algorithm:**
1. Compute graph Laplacian: L = D - A
2. Compute k smallest eigenvectors of L
3. Cluster rows of eigenvector matrix using k-means

**Implementation Details:**
- Uses Rayon for parallel eigenvalue computation
- Sparse matrix operations for efficiency
- Suitable for medium-sized graphs (< 10K nodes)

### SLPA (Speaker-Listener Label Propagation)

**File:** `src/algorithm/community/slpa.rs`

Overlapping community detection using memory-based label propagation.

**Algorithm:**
1. Initialize each node with unique label
2. For T iterations:
   - Each node is a "listener"
   - Random neighbor is "speaker"
   - Listener adds speaker's label to memory
3. Post-processing: Apply threshold to get memberships

**Key Features:**
- Supports overlapping communities
- Threshold controls overlap amount
- Memory-based (stores label history)

### Infomap

**File:** `src/algorithm/community/infomap.rs`

Information-theoretic community detection using the map equation.

**Algorithm:**
1. Treat random walks as information flow
2. Minimize description length of walks
3. Use Huffman coding for community names
4. Optimize module assignments

**Key Features:**
- Based on information theory
- Finds hierarchical communities
- Good for flow-based networks

### Label Propagation

**File:** `src/algorithm/community/label_propagation.rs`

Fast community detection using label spreading.

**Algorithm:**
1. Initialize each node with unique label
2. For each iteration:
   - Nodes adopt most common label among neighbors
   - Random update order to prevent oscillation
3. Repeat until convergence

**Complexity:** O(k × E) where k = iterations

**Best For:** Very large graphs (fastest algorithm)

### Walktrap

**File:** `src/algorithm/community/walktrap.rs`

Random walk-based community detection using similarity measures.

**Algorithm:**
1. Compute random walk transition probabilities
2. Measure distance between nodes based on walks
3. Hierarchical clustering using Ward's method
4. Cut dendrogram at optimal level

**Complexity:** O(n² log n) for n nodes

### Strongly Connected Components (SCC)

**File:** `src/algorithm/community/scc.rs`

Finds strongly connected components using Tarjan's algorithm.

**Algorithm:**
1. DFS traversal assigning discovery times
2. Maintain low-link values
3. Identify SCCs when low-link equals discovery time
4. Pop nodes from stack to form SCC

**Complexity:** O(V + E)

### Connected Components

**File:** `src/algorithm/community/components.rs`

Finds weakly connected components using BFS/DFS.

**Algorithm:**
1. Start BFS from unvisited node
2. All reachable nodes form a component
3. Repeat until all nodes visited

**Complexity:** O(V + E)

## Traversal Algorithms

### BFS (Breadth-First Search)

**File:** `src/algorithm/traversal/bfs.rs`

Level-by-level graph traversal.

**Algorithm:**
1. Initialize queue with start node(s)
2. While queue not empty:
   - Dequeue node
   - Visit node
   - Enqueue unvisited neighbors
3. Track depth for each node

**Complexity:** O(V + E)

### DFS (Depth-First Search)

**File:** `src/algorithm/traversal/dfs.rs`

Deep graph traversal using recursion or explicit stack.

**Algorithm:**
1. Start at root node
2. Recursively explore each branch
3. Backtrack when no unvisited neighbors
4. Track depth for each node

**Complexity:** O(V + E)

## Path Algorithms

### Dijkstra

**File:** `src/algorithm/path/dijkstra.rs`

Shortest path algorithm for weighted graphs.

**Algorithm:**
1. Initialize distances: source = 0, others = infinity
2. Use priority queue to select unvisited node with min distance
3. Relax edges from selected node
4. Repeat until target reached or all nodes visited
5. Reconstruct path from predecessor map

**Complexity:** O(E + V log V) with binary heap

**Features:**
- Supports weighted edges via `weightProperty`
- Returns paths and costs
- Can compute single-source or single-target

## Analytics Algorithms

### Triangle Count

**File:** `src/algorithm/analytics/triangles.rs`

Counts triangles (3-cliques) in the graph.

**Algorithm:**
1. For each node with degree > 1:
   - Get list of neighbors
   - Count edges between neighbors
   - Each such edge forms a triangle
2. Divide by 3 (each triangle counted 3 times)

**Complexity:** O(E × √E) using ordering by degree

**Use Cases:**
- Clustering coefficient computation
- Social network analysis
- Graph density assessment

## Performance Optimizations

### Parallel Processing

- **Rayon:** Used for parallel operations in spectral clustering
- **Thread Pool:** Configurable number of worker threads
- **Lock-Free:** Atomic operations for score updates where possible

### Direct Table Access

Algorithms operate directly on the table layer:
- **NodeTable:** Direct access to node properties
- **RelTable:** CSR-like structures for adjacency
- **No Query Engine:** Bypasses Cypher parsing/execution

### Efficient Adjacency

Relationship tables use CSR (Compressed Sparse Row) format:
- **Offsets:** Array of start indices for each node's edges
- **Targets:** Flat array of target node IDs
- **Properties:** Optional edge properties

**Benefits:**
- Cache-friendly sequential access
- O(degree) neighbor iteration
- Compact storage

## N-API Integration

**File:** `src/napi/connection/algorithm.rs`

The N-API layer exposes algorithms to JavaScript:

```rust
#[napi]
fn run_algorithm_sync(
    &self,
    algorithm_name: String,
    config_json: String
) -> String {
    // Parse config
    let config: AlgorithmConfig = serde_json::from_str(&config_json)?;

    // Run algorithm
    let result = self.conn.run_algorithm(&algorithm_name, &config)?;

    // Serialize result
    serde_json::to_string(&result)?
}
```

## Error Handling

Algorithm-specific errors:

```rust
pub enum AlgorithmError {
    UnknownAlgorithm(String),
    InvalidConfig(String),
    GraphTooLarge,
    ConvergenceFailed,
    DisconnectedGraph,
}
```

## Testing

Each algorithm has comprehensive tests:
- Unit tests for correctness on known graphs
- Performance tests on synthetic data
- Edge case tests (empty, single node, disconnected)

## Streaming API (v0.1.9+)

CongraphDB v0.1.9+ includes a streaming API for memory-efficient algorithm execution on large graphs.

### Streaming Results

Algorithms can return results in batches to avoid loading all results into memory at once:

```rust
pub enum AlgorithmResult {
    NodeScores(Vec<(NodeOffset, f64)>),
    NodeLabels(Vec<(NodeOffset, u64)>),
    TraversalOrder(Vec<(NodeOffset, usize)>),
    ShortestPaths(Vec<PathResult>),
    TriangleCount(TriangleCountResult),
    Streaming {
        batch_size: usize,
        total_batches: Option<usize>,
        // ... streaming-specific fields
    },
}
```

### Memory Benefits

- **Large-scale analytics** - Process graphs larger than available memory
- **Real-time results** - Start processing results before algorithm completes
- **Reduced footprint** - Only keep current batch in memory

### Usage Example

```javascript
// Streaming algorithm execution
const result = conn.runAlgorithmSync('pagerank', JSON.stringify({
  dampingFactor: 0.85,
  streaming: true,
  batchSize: 1000
}));

// Process results as they arrive
const scores = JSON.parse(result);
for (const batch of scores.batches) {
  processBatch(batch);  // Handle each batch incrementally
}
```

## Future Enhancements

### Planned Algorithms

- **k-Core Decomposition** - Find core-periphery structure
- **Community Detection:** Label Propagation with weights
- **Centrality:** Eigenvector centrality
- **Path:** A* algorithm with heuristic

### Optimizations

- **GPU Acceleration** for PageRank and spectral clustering
- **Incremental Updates** for dynamic graphs
- **Approximation Algorithms** for faster results

## References

- Newman, M. E. (2006). "Modularity and community structure in networks"
- Blondel, V. D., et al. (2008). "Fast unfolding of communities in large networks"
- Rosvall, M., & Bergstrom, C. T. (2008). "Maps of random walks on complex networks"
- Xie, J., & Szymanski, B. K. (2011). "SLPA: Uncovering overlapping communities in social networks"

## See Also

- [Algorithm Usage Guide](../guide/algorithms.md) — How to use algorithms
- [Architecture](architecture.md) — Overall system architecture
