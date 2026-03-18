# CongraphDB Documentation

Official documentation for [CongraphDB](https://github.com/congraph-ai/congraphdb) — A high-performance, embedded graph database for Node.js built with Rust

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt
npm install

# Build documentation
mkdocs build

# Serve locally (with live reload)
mkdocs serve

# Open browser at http://localhost:8000
```

## Project Structure

```
congraphdb-docs/
├── docs/                    # Documentation content
│   ├── guide/              # User guides
│   ├── api/                # API reference
│   ├── internals/          # Architecture docs
│   ├── operators/          # Cypher operators
│   ├── releases/           # Release notes
│   └── blog/               # Blog posts
├── overrides/              # Theme customization
├── scripts/                # Build scripts
└── mkdocs.yml              # MkDocs configuration
```

## Building Documentation

### Local Development

```bash
mkdocs serve
```

### Production Build

```bash
mkdocs build
```

### Deploy to GitHub Pages

```bash
mike deploy --push --update-aliases latest
```

## Versioning

This documentation site supports multiple versions using [Mike](https://github.com/jimporter/mike):

- **Latest**: Current stable release
- **Dev**: Development version (main branch)
- **v0.1.x**: Specific versioned documentation

## Contributing

Contributions are welcome! Please see:

1. [Contributing Guide](https://congraphdb.readthedocs.io/en/latest/internals/contributing/) (in the docs)
2. [GitHub Issues](https://github.com/congraph-ai/congraphdb-docs/issues)

### Adding Documentation

1. Edit Markdown files in `docs/`
2. Run `mkdocs serve` to preview
3. Submit a pull request

### Adding Blog Posts

1. Create new file in `docs/blog/posts/`
2. Add frontmatter with title, date, description
3. Update `docs/blog/index.md` if needed

## License

MIT License — see [LICENSE](LICENSE) file for details.

## Links

- **Main Repository**: [congraph-ai/congraphdb](https://github.com/congraph-ai/congraphdb)
- **npm Package**: [congraphdb](https://www.npmjs.com/package/congraphdb)
- **Documentation**: [congraph-ai.github.io/congraphdb-docs](https://congraph-ai.github.io/congraphdb-docs/)
