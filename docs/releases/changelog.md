# Changelog

All notable changes to CongraphDB will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2026-03-21

### Added
- **v0.1.6 synchronization** — Updated documentation for CongraphDB v0.1.6
- Added "What's New in v0.1.6" section to index page

### Changed
- Updated version references from v0.1.5 to v0.1.6 across all documentation

## [1.0.5] - 2026-03-18

### Added
- **Dual Query Interface** documentation — Choose between Cypher Query Language OR JavaScript-Native API
  - **CongraphDBAPI class** documentation with NodeAPI, EdgeAPI, Pattern, and Navigator
  - **Navigator API** documentation for fluent graph traversal
  - **TypeScript definitions** documentation
- **Complete DML operations** documentation — CREATE, SET, DELETE, REMOVE, MERGE with ON MATCH/ON CREATE
- **Query execution statistics** documentation — Track execution time, row count, and query type
- **Dynamic property creation** documentation — Auto-create columns when setting non-existent properties
- **Property filter handling** documentation — Property filters in MATCH patterns
- **CASE expressions** documentation — Full conditional logic support in queries
- Added "What's New in v0.1.5" section to index page

### Changed
- Synchronized documentation with congraphdb v0.1.5 features

## [1.0.4] - 2026-03-15

### Added
- Complete **Pattern Comprehensions** documentation in queries guide
- Complete **Temporal Types** documentation (Date, DateTime, Duration)
- Complete **Multi-label Nodes** documentation
- Complete **Map Literals** documentation
- Enhanced **Path Finding Functions** documentation
- Added temporal functions to Cypher reference
- Added node and label functions to Cypher reference
- Added pattern comprehensions and map literals to patterns section
- Added "What's New in v0.1.5" section to index page

### Changed
- Synchronized documentation with congraphdb v0.1.3 and v0.1.4 features

## [1.0.3] - 2026-03-15

### Changed
- Documentation updated for CongraphDB v0.1.4

### Fixed
- Updated changelog with v0.1.3 feature details
- Fixed GitHub Actions artifact naming conflict (main repo)

## [1.0.2] - 2026-03-15

### Added
- **Path finding functions** documentation
  - `shortestPath()` - Find the shortest path between two nodes
  - `allShortestPaths()` - Find all shortest paths at minimum length
  - Configurable max path length with `[*..n]` syntax
  - Support for all relationship directions (Outgoing, Incoming, Undirected)
- **Pattern comprehensions** documentation
  - Single-node patterns: `[(n:Label) | n.prop]`
  - Relationship patterns: `[(a)-[:REL]->(b) | b.prop]`
  - Multi-hop patterns: `[(a)-[:KNOWS]->(b)-[:FOLLOWS]->(c) | c]`
  - WHERE clause support within comprehensions
  - Outer variable scope - reference variables from outer query context
- **Temporal types** documentation
  - `Date` type for calendar dates (year, month, day)
  - `DateTime` type for timestamps (milliseconds since epoch)
  - `Duration` type for time spans
  - `date()` function - Parse or create date values
  - `datetime()` function - Get current datetime or parse datetime strings
  - `timestamp()` function - Get current Unix timestamp in milliseconds
  - `duration()` function - Parse ISO 8601 duration strings
- **Multi-label nodes** documentation
  - Nodes can have multiple labels: `(u:User:Admin:Premium)`
  - `labels()` function returns all labels as a list
  - `has_label()`, `add_label()`, `remove_label()` methods on NodeValue
- **Map literals** documentation
  - Create maps with `{key: value, ...}` syntax
  - Support for arbitrary key-value pairs
- **PathValue** type documentation
  - Contains ordered nodes and relationships
  - `length()`, `node_count()`, `start_node()`, `end_node()` methods
  - Support for single-node paths (path from node to itself)

### Changed
- Synchronized version with main library release v0.1.3

## [1.0.1] - 2026-03-15

### Changed
- Documentation updated for CongraphDB v0.1.3.1
- Synchronized version with main library release

## [Unreleased]

### Added
- Planned features for next release

## [0.1.2] - 2024-03-14

### Added
- Initial documentation site with GitHub Pages
- MkDocs with Material theme configuration
- Versioning support with Mike plugin
- Complete API reference documentation
- User guides for installation, quick start, schemas, queries
- Transaction and vector search guides
- Performance and deployment guides
- Internal architecture documentation
- Operator reference documentation

### Changed
- Improved documentation structure
- Updated README with docs link

## [0.1.1] - 2024-03-10

### Added
- CHANGELOG.md
- CONTRIBUTING.md
- DISCLAIMER.md

### Fixed
- Build configuration improvements

## [0.1.0] - 2024-03-01

### Added
- Initial release of CongraphDB
- Core storage engine with columnar storage
- Basic Cypher query support
- ACID transactions with WAL
- Node.js bindings via napi-rs
- HNSW vector index for similarity search
- Windows, macOS, and Linux support

### Features
- Embedded, serverless graph database
- Single-file storage (.cgraph)
- Write-ahead logging (.wal)
- Memory-mapped I/O
- Parallel query execution
- Snappy compression support

## Version Format

- `[Unreleased]` — Features being worked on
- `[0.1.2]` — Released versions with dates

For the full changelog from the main repository, see the [CHANGELOG.md](https://github.com/congraph-ai/congraphdb/blob/main/CHANGELOG.md).

## See Also

- [Migration Guide](migration.md) — Upgrading between versions
