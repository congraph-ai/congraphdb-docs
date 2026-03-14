# Contributing

Thank you for your interest in contributing to CongraphDB!

## Getting Started

### Prerequisites

- Rust 1.70 or later
- Node.js 20 or later
- Git

### Build from Source

```bash
# Clone the repository
git clone https://github.com/congraph-ai/congraphdb.git
cd congraphdb

# Install dependencies
npm install

# Build the native module
npm run build

# Run tests
npm test
```

## Development Workflow

### Making Changes

1. Fork the repository
2. Create a branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `npm test`
5. Commit: `git commit -m "Add my feature"`
6. Push: `git push origin feature/my-feature`
7. Open a pull request

### Code Style

- **Rust**: Follow `rustfmt` and `clippy` recommendations
- **JavaScript/TypeScript**: Follow ESLint configuration
- **Commits**: Use conventional commit messages

```bash
# Format Rust code
cargo fmt

# Lint Rust code
cargo clippy -- -D warnings

# Lint JavaScript
npm run lint
```

## Project Structure

```
congraphdb/
├── src/
│   ├── lib.rs           # napi-rs bindings
│   ├── core/            # Core engine
│   ├── storage/         # Storage engine
│   ├── query/           # Query engine
│   ├── table/           # Table management
│   ├── index/           # Index structures
│   └── types/           # Shared types
├── test/                # Integration tests
├── benches/             # Benchmarks
└── npm/                 # npm package files
```

## Testing

### Unit Tests (Rust)

```bash
# Run all tests
npm run test:rust

# Run specific test
cargo test test_name

# Run with output
cargo test -- --nocapture
```

### Integration Tests (JavaScript)

```bash
# Run all tests
npm test

# Run specific test file
npm test -- test/query.test.js
```

### Adding Tests

Tests go in:
- `src/` for Rust unit tests (`#[test]`)
- `test/` for JavaScript integration tests

## Documentation

### Rust Documentation

```rust
/// Adds two numbers together.
///
/// # Examples
///
/// ```
/// let result = add(2, 3);
/// assert_eq!(result, 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### API Documentation

Update the docs repo:

```bash
cd ../congraphdb-docs
# Update documentation
git commit -m "docs: update API reference"
```

## Benchmarks

Run benchmarks:

```bash
# Run all benchmarks
npm run bench

# Run specific benchmark
cargo bench --bench query_benchmarks
```

## Pull Request Guidelines

### PR Checklist

- [ ] Tests pass (`npm test`)
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] No merge conflicts
- [ ] Code formatted (`cargo fmt`)
- [ ] No clippy warnings

### PR Description

Include:
- Summary of changes
- Motivation for the change
- Breaking changes (if any)
- Related issues

## Areas to Contribute

### High Priority

- [ ] Complete Cypher query support
- [ ] Improve test coverage
- [ ] Documentation improvements
- [ ] Performance benchmarks

### Medium Priority

- [ ] Additional index types (B-tree, full-text)
- [ ] Query optimization rules
- [ ] Async iteration for QueryResult
- [ ] Better error messages

### Low Priority

- [ ] Graph analytics algorithms
- [ ] GraphQL endpoint
- [ ] WebAssembly support
- [ ] Language drivers (Python, Go, etc.)

## Getting Help

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Discord**: (coming soon)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build something great together.

Thank you for contributing! :tada:
