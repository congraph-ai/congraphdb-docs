# Changelog

All notable changes to CongraphDB will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
